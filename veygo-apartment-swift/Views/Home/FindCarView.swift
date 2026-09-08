//
//  FindCarView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/7/26.
//

import SwiftUI
import MapKit

struct FindCarView: View {
    struct Availability: Decodable {
        var offer: RateOffer
        var vehicles: [LocationWithVehicles]
        var taxes: [Tax]
    }

    @Environment(Session.self) private var session
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss

    // Carried in from HomeDestination.university — values, not bindings.
    let apartment: Apartment
    let startDate: Date
    let endDate: Date
    let promo: PublishPromo?

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var popOnAlertDismiss: Bool = false

    @State private var locationManager = CLLocationManager()

    @State private var selectedLocation: Location.ID? = nil
    @State private var selectedVehicle: PublishRenterVehicle.ID? = nil
    @State private var locations: Availability? = nil
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var savedPosition: MapCameraPosition? = nil

    private func coordinate(for l: LocationWithVehicles) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: l.location.latitude, longitude: l.location.longitude)
    }

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedLocation) {
            UserAnnotation()

            if let availability = locations {
                ForEach(availability.vehicles, id: \.id) { locationWithVehicles in
                    Marker(
                        locationWithVehicles.location.name,
                        systemImage: "car",
                        coordinate: coordinate(for: locationWithVehicles)
                    )
                    .tag(locationWithVehicles.id)
                    .tint(.purple)
                    .annotationSubtitles(.visible)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedLocation)
        .mapStyle(.standard(elevation: .flat, emphasis: .automatic, pointsOfInterest: .excludingAll, showsTraffic: true))
        .mapControls {
            MapCompass()
            if locationManager.authorizationStatus == .authorizedWhenInUse {
                MapUserLocationButton()
            }
        }
        .onChange(of: selectedLocation) { _, newValue in
            if let sel = newValue {
                guard let locations,
                      let loc = locations.vehicles.first(where: { $0.id == sel }) else { return }
                let coord = CLLocationCoordinate2D(latitude: loc.location.latitude, longitude: loc.location.longitude)
                withAnimation(.smooth) {
                    cameraPosition = .camera(MapCamera(centerCoordinate: coord, distance: 3_600, heading: 0, pitch: 0))
                }
            } else if let saved = savedPosition {
                withAnimation(.smooth) {
                    cameraPosition = saved
                }
            }
        }
        .sheet(
            isPresented: Binding(
                get: { selectedLocation != nil },
                set: { if !$0 { selectedLocation = nil } }
            )
        ) {
            if let locations {
                LocationStripView(
                    selectedLocation: $selectedLocation,
                    selectedVehicle: $selectedVehicle,
                    locations: locations.vehicles,
                    apartment: apartment,
                    startDate: startDate,
                    endDate: endDate,
                    rateOffer: locations.offer,
                    taxes: locations.taxes,
                    promo: promo
                )
                .presentationDetents([.height(300)])
                .presentationBackgroundInteraction(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if popOnAlertDismiss {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        selectedLocation = nil
                    }
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        selectedLocation = nil
                    }
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            locationManager.requestWhenInUseAuthorization()
            await loadAvailability()
        }
    }

    // MARK: - Load availability

    private func loadAvailability() async {
        do {
            let availability = try await fetchAvailability()
            locations = availability
            if availability.vehicles.isEmpty {
                present(title: "No cars available",
                        message: "Uh oh, this university isn't ready. Please try again later.",
                        popAfter: true)
            }
            await updateWalkingETAs()
        } catch let error as VeygoError {
            switch error {
            case .unauthorized:
                session.clear()
                present(error.display)
            case .server(let status, _) where status == 400 || status == 403:
                present(error.display, popAfter: true)   // bad request / forbidden → back out
            case .decoding:
                present(.E_DEFAULT, popAfter: true)
            default:
                present(error.display)
            }
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func fetchAvailability() async throws -> Availability {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else { throw VeygoError.unknown }

        let body = [
            "start_time": Int(startDate.timeIntervalSince1970),
            "end_time": Int(endDate.timeIntervalSince1970),
            "apartment_id": apartment.id
        ]
        let jsonData = try VeygoJsonStandard.shared.encoder.encode(body)
        let request = veygoCurlRequest(
            url: "/api/v1/vehicle/availability",
            method: .post,
            headers: ["auth": "\(token)$\(userId)"],
            body: jsonData
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw VeygoError.unknown }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return try VeygoJsonStandard.shared.decoder.decode(Availability.self, from: data)
            } else if httpCode == 400 {
                // This endpoint returns { "error": "..." } on 400, not the standard shape.
                let decoded = try VeygoJsonStandard.shared.decoder.decode(AvailabilityErrorBody.self, from: data)
                throw VeygoError.server(status: 400, error: ErrorResponse(title: "Invalid Request", message: decoded.error))
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.unauthorized(decodedError)
            } else {
                let decodedError = (try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)) ?? .E_DEFAULT
                throw VeygoError.server(status: httpCode, error: decodedError)
            }
        } catch let error as URLError {
            throw VeygoError.network(error)
        } catch _ as DecodingError {
            throw VeygoError.decoding
        } catch let error as VeygoError {
            throw error
        } catch {
            throw VeygoError.unknown
        }
    }

    // MARK: - Walking ETAs / camera fit

    private func updateWalkingETAs() async {
        guard var locations else { return }
        guard [.authorizedWhenInUse, .authorizedAlways].contains(locationManager.authorizationStatus),
              let userCoord = locationManager.location?.coordinate else { return }

        for i in locations.vehicles.indices {
            let dest = CLLocationCoordinate2D(
                latitude: locations.vehicles[i].location.latitude,
                longitude: locations.vehicles[i].location.longitude
            )
            do {
                let seconds = try await walkingETASeconds(from: userCoord, to: dest)
                locations.vehicles[i].duration = seconds / 60.0
            } catch {
                print(error.localizedDescription)
            }
        }

        self.locations = locations

        if let region = fitAllLocationsRegion(paddingPercent: 0.75) {
            withAnimation(.easeInOut(duration: 3)) {
                cameraPosition = .region(region)
                savedPosition = cameraPosition
            }
        }
    }

    private func fitAllLocationsRegion(paddingPercent: Double) -> MKCoordinateRegion? {
        guard let locations, !locations.vehicles.isEmpty else { return nil }

        var minLat = 90.0, maxLat = -90.0
        var minLon = 180.0, maxLon = -180.0
        for l in locations.vehicles {
            minLat = min(minLat, l.location.latitude); maxLat = max(maxLat, l.location.latitude)
            minLon = min(minLon, l.location.longitude); maxLon = max(maxLon, l.location.longitude)
        }

        if minLat == maxLat && minLon == maxLon {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: minLat, longitude: minLon),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }

        var span = MKCoordinateSpan(latitudeDelta: maxLat - minLat, longitudeDelta: maxLon - minLon)
        span.latitudeDelta *= (1.0 + paddingPercent)
        span.longitudeDelta *= (1.0 + paddingPercent)
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
            span: span
        )
    }

    // MARK: - Alert

    private func present(_ error: ErrorResponse, popAfter: Bool = false) {
        present(title: error.title, message: error.message, popAfter: popAfter)
    }

    private func present(title: String, message: String, popAfter: Bool = false) {
        alertTitle = title
        alertMessage = message
        popOnAlertDismiss = popAfter
        showAlert = true
    }
}

/// Non-standard 400 body from /vehicle/availability.
private struct AvailabilityErrorBody: Decodable {
    let error: String
}

func walkingETASeconds(from: CLLocationCoordinate2D,
                       to: CLLocationCoordinate2D) async throws -> TimeInterval {
    let src = MKMapItem(location: CLLocation(latitude: from.latitude, longitude: from.longitude), address: nil)
    let dst = MKMapItem(location: CLLocation(latitude: to.latitude, longitude: to.longitude), address: nil)

    let req = MKDirections.Request()
    req.source = src
    req.destination = dst
    req.transportType = .walking
    req.requestsAlternateRoutes = true

    let response = try await MKDirections(request: req).calculate()
    guard let route = response.routes.first else {
        throw NSError(domain: "Directions", code: 0, userInfo: [NSLocalizedDescriptionKey: "No walking route"])
    }
    return route.expectedTravelTime
}

// MARK: - Vehicle card (unchanged)

struct VehicleCardView: View {
    let vehicle: VehicleWithBlockedDurations
    let apartment: Apartment
    let rateOffer: RateOffer
    let startDate: Date
    let endDate: Date

    private let availabilityBarHeight: CGFloat = 8
    private let availabilityBarBorderWidth: CGFloat = 0.8
    private let availabilityBarTrackColor: Color = Color(.systemBackground)
    private let availabilityBarBorderColor: Color = Color(.systemGray4)
    private let availabilityColorClear: Color = .clear
    private let availabilityColorUnavailableOutsideRequest: Color = Color(.systemGray4)
    private let availabilityHatchLineColor: Color = Color(.systemGray2)
    private let availabilityHatchLineWidth: CGFloat = 0.8
    private let availabilityHatchSpacing: CGFloat = 2.4
    private let availabilityColorRequestedAvailable: Color = Color(.systemGreen)
    private let availabilityColorRequestedUnavailable: Color = Color(.systemRed)

    private enum AvailabilityState: Equatable {
        case clear, unavailableOutsideRequest, requestedAvailable, requestedUnavailable
    }

    private struct AvailabilitySegment: Identifiable {
        let id = UUID()
        let start: Date
        let end: Date
        let state: AvailabilityState
    }

    private struct CollapsedSegment {
        var start: Date
        var end: Date
        var state: AvailabilityState
    }

    private func stateForBlock(wanted: Bool, taken: Bool) -> AvailabilityState {
        if wanted { return taken ? .requestedUnavailable : .requestedAvailable }
        return taken ? .unavailableOutsideRequest : .clear
    }

    private func color(for state: AvailabilityState) -> Color {
        switch state {
        case .clear:                     return availabilityColorClear
        case .unavailableOutsideRequest: return availabilityColorUnavailableOutsideRequest
        case .requestedAvailable:        return availabilityColorRequestedAvailable
        case .requestedUnavailable:      return availabilityColorRequestedUnavailable
        }
    }

    private struct DiagonalHatchFill: View {
        let backgroundColor: Color
        let lineColor: Color
        let lineWidth: CGFloat
        let lineSpacing: CGFloat

        var body: some View {
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
                let inset = lineWidth / 2
                let step = lineSpacing + lineWidth
                ZStack {
                    Rectangle().fill(backgroundColor)
                    Path { path in
                        var x: CGFloat = -height
                        while x < width {
                            path.move(to: CGPoint(x: x, y: inset))
                            path.addLine(to: CGPoint(x: x + height - inset * 2, y: height - inset))
                            x += step
                        }
                    }
                    .stroke(lineColor, lineWidth: lineWidth)
                }
                .clipped()
            }
        }
    }

    private func overlaps(_ aStart: Date, _ aEnd: Date, _ bStart: Date, _ bEnd: Date) -> Bool {
        max(aStart, bStart) < min(aEnd, bEnd)
    }

    private func paddedWindow() -> (start: Date, end: Date)? {
        let requestedDuration = endDate.timeIntervalSince(startDate)
        guard requestedDuration > 0 else { return nil }
        let wholeDays = max(0, Int(requestedDuration / 86_400))
        let paddedStart = startDate.addingTimeInterval(-3_600)
        let paddedEnd = startDate.addingTimeInterval(TimeInterval(wholeDays + 1) * 86_400)
        guard paddedEnd > paddedStart else { return nil }
        return (paddedStart, paddedEnd)
    }

    private func makeAvailabilitySegments() -> [AvailabilitySegment] {
        guard let window = paddedWindow() else { return [] }
        let slice: TimeInterval = 15 * 60
        var collapsed: [CollapsedSegment] = []
        var cursor = window.start

        while cursor < window.end {
            let next = min(cursor.addingTimeInterval(slice), window.end)
            let wanted = overlaps(cursor, next, startDate, endDate)
            let taken = vehicle.blockedDurations.contains { blocked in
                overlaps(cursor, next, blocked.startTime, blocked.endTime)
            }
            let state = stateForBlock(wanted: wanted, taken: taken)

            if var last = collapsed.last, last.state == state {
                last.end = next
                collapsed[collapsed.count - 1] = last
            } else {
                collapsed.append(CollapsedSegment(start: cursor, end: next, state: state))
            }
            cursor = next
        }

        return collapsed.map { AvailabilitySegment(start: $0.start, end: $0.end, state: $0.state) }
    }

    @ViewBuilder
    private var availabilityBar: some View {
        if let window = paddedWindow() {
            let segments = makeAvailabilitySegments()
            let totalDuration = window.end.timeIntervalSince(window.start)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(availabilityBarTrackColor)
                    Capsule().stroke(availabilityBarBorderColor, lineWidth: availabilityBarBorderWidth)

                    ForEach(segments) { segment in
                        if segment.state == .unavailableOutsideRequest {
                            let segmentOffset = CGFloat(segment.start.timeIntervalSince(window.start) / totalDuration) * geo.size.width
                            let segmentWidth = max(1, CGFloat(segment.end.timeIntervalSince(segment.start) / totalDuration) * geo.size.width)
                            DiagonalHatchFill(
                                backgroundColor: availabilityColorUnavailableOutsideRequest,
                                lineColor: availabilityHatchLineColor,
                                lineWidth: availabilityHatchLineWidth,
                                lineSpacing: availabilityHatchSpacing
                            )
                            .frame(width: segmentWidth, height: geo.size.height)
                            .clipped()
                            .offset(x: segmentOffset)
                        }
                    }

                    ForEach(segments) { segment in
                        if segment.state == .requestedAvailable || segment.state == .requestedUnavailable {
                            let segmentOffset = CGFloat(segment.start.timeIntervalSince(window.start) / totalDuration) * geo.size.width
                            let segmentWidth = max(1, CGFloat(segment.end.timeIntervalSince(segment.start) / totalDuration) * geo.size.width)
                            Rectangle()
                                .fill(color(for: segment.state))
                                .frame(width: segmentWidth, height: geo.size.height)
                                .offset(x: segmentOffset)
                        }
                    }
                }
                .clipShape(Capsule())
            }
            .frame(height: availabilityBarHeight)
        } else {
            Capsule()
                .stroke(availabilityBarBorderColor, lineWidth: availabilityBarBorderWidth)
                .frame(height: availabilityBarHeight)
        }
    }

    private var hourlyRateText: String {
        let rate = vehicle.vehicle.msrpFactor.value * apartment.durationRate.value * rateOffer.multiplier.value
        return VeygoCurrencyStandard.shared.dollarFormatter.string(from: rate as NSDecimalNumber) ?? "$0.00"
    }

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(vehicle.vehicle.make) \(vehicle.vehicle.model)")
                        Text(vehicle.vehicle.name).fontWeight(.light)
                    }
                    Text("\(hourlyRateText)/hr")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("SecondaryButtonText"))
                    HStack {
                        Image(systemName: "fuelpump")
                        Text(" \(vehicle.vehicle.tankLevelPercentage)%")
                    }
                }
                Spacer()
                Image("TempVehicle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80)
            }
            availabilityBar
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background { Color("CardBG") }
        .cornerRadius(18)
        .shadow(radius: 0.5)
    }
}

// MARK: - Location strip (sheet)

private struct LocationVehicleCard: View {
    let loc: LocationWithVehicles
    let vehicle: VehicleWithBlockedDurations
    let apartment: Apartment
    let rateOffer: RateOffer
    let startDate: Date
    let endDate: Date
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(loc.location.name).font(.title3)
                Spacer()
                if let duration = loc.duration {
                    Image(systemName: "figure.walk")
                    Text("\(String(format: "%.0f", duration)) minutes")
                }
            }
            .padding(.horizontal)

            VehicleCardView(vehicle: vehicle, apartment: apartment, rateOffer: rateOffer, startDate: startDate, endDate: endDate)
                .frame(width: 340)
                .onTapGesture(perform: onSelect)
        }
    }
}

private struct LocationStripView: View {
    @Environment(Router.self) private var router

    @Binding var selectedLocation: Location.ID?
    @Binding var selectedVehicle: PublishRenterVehicle.ID?
    let locations: [LocationWithVehicles]
    let apartment: Apartment
    let startDate: Date
    let endDate: Date
    let rateOffer: RateOffer
    let taxes: [Tax]
    let promo: PublishPromo?

    var body: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(locations.indices, id: \.self) { index in
                        let loc = locations[index]

                        HStack(spacing: 16) {
                            ForEach(loc.vehicles, id: \.id) { v in
                                LocationVehicleCard(
                                    loc: loc,
                                    vehicle: v,
                                    apartment: apartment,
                                    rateOffer: rateOffer,
                                    startDate: startDate,
                                    endDate: endDate,
                                    onSelect: {
                                        selectedLocation = nil
                                        router.push(HomeDestination.vehicleDetails(
                                            vehicle: v,
                                            location: loc.location,
                                            apartment: apartment,
                                            rateOffer: rateOffer,
                                            taxes: taxes,
                                            startDate: startDate,
                                            endDate: endDate,
                                            promo: promo
                                        ))
                                    }
                                )
                            }
                        }
                        .padding(.leading, 16)
                        .padding(.trailing, (index == locations.count - 1) ? 16 : 0)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $selectedLocation)
            .scrollIndicators(.hidden)

            Text("* Veygo requires full coverage insurance at all times.")
                .font(.caption.italic())
                .padding(.leading, 32)
        }
    }
}
