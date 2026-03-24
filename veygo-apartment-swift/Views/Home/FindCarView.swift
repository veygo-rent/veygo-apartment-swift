//
//  FindCarView.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/1/25.
//

import SwiftUI
import MapKit

struct FindCarView: View {
    nonisolated struct Availability: Decodable {
        var offer: RateOffer
        var vehicles: [LocationWithVehicles]
        var taxes: [Tax]
    }
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    @State private var backButtonTriggered: Bool = false
    
    @State private var locationManager = CLLocationManager()
    
    @Binding var path: [HomeDestination]
    
    @EnvironmentObject var session: UserSession
    
    @Binding var startDate: Date
    @Binding var endDate: Date
    var apartment: Apartment
    
    @State private var selectedLocation: Location.ID? = nil
    @State private var selectedVehicle: PublishRenterVehicle.ID? = nil
    @State private var locations: Availability? = nil
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    @State private var savedPosition: MapCameraPosition? = nil
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
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
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .all, showsTraffic: true))
        .mapControls {
            MapCompass()
            if locationManager.authorizationStatus == .authorizedWhenInUse {
                MapUserLocationButton()
            }
        }
        .onChange(of: selectedLocation) { _, newValue in
            if let sel = newValue {
                guard let locations else { return }
                guard let loc = locations.vehicles.first(where: { $0.id == sel }) else { return }
                let coord = CLLocationCoordinate2D(latitude: loc.location.latitude, longitude: loc.location.longitude)
                withAnimation(.smooth) {
                    cameraPosition = .camera(MapCamera(centerCoordinate: coord, distance: 3_600, heading: 0, pitch: 0))
                }
            } else {
                guard let saved = savedPosition else { return }
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
                    path: $path,
                    selectedLocation: $selectedLocation,
                    selectedVehicle: $selectedVehicle,
                    locations: locations.vehicles,
                    apartment: apartment,
                    startDate: startDate,
                    endDate: endDate,
                    rateOffer: locations.offer,
                    taxes: locations.taxes
                )
                .presentationDetents([.height(300)])
                .presentationBackgroundInteraction(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if clearUserTriggered {
                    session.user = nil
                }
                if backButtonTriggered {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        selectedLocation = nil
                    }
                    path.removeLast()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .navigationTitle(formattedDateRange)
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        selectedLocation = nil
                    }
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                }
            }
        })
        .navigationBarBackButtonHidden(true)
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
            Task {
                await ApiCallActor.shared.appendApi { token, userId in
                    await loadLocationsAsync(token, userId)
                }
                await updateWalkingETAs()
            }
        }
    }
    
    // Compute a region that fits all locations with a little extra padding.
    @MainActor private func fitAllLocationsRegion(paddingPercent: Double) -> MKCoordinateRegion? {
        guard let locations else { return nil }
        guard !locations.vehicles.isEmpty else { return nil }

        var minLat =  90.0, maxLat = -90.0
        var minLon = 180.0, maxLon = -180.0
        for l in locations.vehicles {
            let lat = l.location.latitude
            let lon = l.location.longitude
            minLat = min(minLat, lat); maxLat = max(maxLat, lat)
            minLon = min(minLon, lon); maxLon = max(maxLon, lon)
        }

        // If there's only one point, use a small default span.
        if minLat == maxLat && minLon == maxLon {
            let center = CLLocationCoordinate2D(latitude: minLat, longitude: minLon)
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            return MKCoordinateRegion(center: center, span: span)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        var span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat),
            longitudeDelta: (maxLon - minLon)
        )
        span.latitudeDelta *= (1.0 + paddingPercent)
        span.longitudeDelta *= (1.0 + paddingPercent)
        return MKCoordinateRegion(center: center, span: span)
    }
    
    @ApiCallActor func loadLocationsAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                
                let body = await [
                    "start_time": Int(startDate.timeIntervalSince1970),
                    "end_time": Int(endDate.timeIntervalSince1970),
                    "apartment_id": apartment.id
                ]
                
                let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(body)
                
                let request = veygoCurlRequest(
                    url: "/api/v1/vehicle/availability",
                    method: .post,
                    headers: [
                        "auth": "\(token)$\(userId)"
                    ],
                    body: jsonData
                )
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid protocol"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                switch httpResponse.statusCode {
                case 200:
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(Availability.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                            backButtonTriggered = true
                        }
                        return .doNothing
                    }
                    if decodedBody.vehicles.isEmpty {
                        await MainActor.run {
                            alertTitle = "No cars available"
                            alertMessage = "Uh oh, this university isn't ready. Please try again later."
                            showAlert = true
                            backButtonTriggered = true
                        }
                    }
                    await MainActor.run {
                        self.locations = decodedBody
                    }
                    Task { await updateWalkingETAs() }
                    return .doNothing
                case 400:
                    nonisolated struct FetchSuccessBody: Decodable {
                        let error: String
                    }
                    
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(FetchSuccessBody.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        alertTitle = "Invalid Request"
                        alertMessage = decodedBody.error
                        showAlert = true
                        backButtonTriggered = true
                    }
                    return .doNothing
                case 401:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E401
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    }
                    return .clearUser
                case 403:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            backButtonTriggered = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E403
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            backButtonTriggered = true
                        }
                    }
                    return .doNothing
                case 405:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E405
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    }
                    return .doNothing
                default:
                    let body = ErrorResponse.E_DEFAULT
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                    return .doNothing
                }
            }
            return .doNothing
        } catch {
            await MainActor.run {
                alertTitle = "Internal Error"
                alertMessage = "\(error.localizedDescription)"
                showAlert = true
            }
            return .doNothing
        }
    }
    
    // Recompute walking ETAs for all loaded locations
    @MainActor private func updateWalkingETAs() async {
        // Require location permission and a known user coordinate
        
        guard var locations else { return }
        guard [.authorizedWhenInUse, .authorizedAlways].contains(locationManager.authorizationStatus),
              let userCoord = locationManager.location?.coordinate else { return }

        // Compute ETAs and store in hours for display
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
        
        if let re = fitAllLocationsRegion(paddingPercent: 0.75) {
            withAnimation(.easeInOut(duration: 3)) {
                cameraPosition = .region(re)
                savedPosition = cameraPosition
            }
        }
    }
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

    let directions = MKDirections(request: req)
    let response = try await directions.calculate()
    // Take the first route (there can be several)
    guard let route = response.routes.first else {
        throw NSError(domain: "Directions", code: 0, userInfo: [NSLocalizedDescriptionKey: "No walking route"])
    }
    return route.expectedTravelTime // seconds
}

struct VehicleCardView: View {
    let vehicle: VehicleWithBlockedDurations
    let apartment: Apartment
    let rateOffer: RateOffer
    let startDate: Date
    let endDate: Date

    // Availability bar styling (easy to tweak)
    private let availabilityBarHeight: CGFloat = 6
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
        case clear
        case unavailableOutsideRequest
        case requestedAvailable
        case requestedUnavailable
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
        if wanted {
            return taken ? .requestedUnavailable : .requestedAvailable
        } else {
            return taken ? .unavailableOutsideRequest : .clear
        }
    }

    private func color(for state: AvailabilityState) -> Color {
        switch state {
        case .clear:
            return availabilityColorClear
        case .unavailableOutsideRequest:
            return availabilityColorUnavailableOutsideRequest
        case .requestedAvailable:
            return availabilityColorRequestedAvailable
        case .requestedUnavailable:
            return availabilityColorRequestedUnavailable
        }
    }

    private struct DiagonalHatchFill: View {
        let backgroundColor: Color
        let lineColor: Color
        let lineWidth: CGFloat
        let lineSpacing: CGFloat

        var body: some View {
            GeometryReader { geo in
                ZStack {
                    Rectangle().fill(backgroundColor)
                    Path { path in
                        let width = geo.size.width
                        let height = geo.size.height
                        let step = lineSpacing + lineWidth
                        var x: CGFloat = -height
                        while x < width {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x + height, y: height))
                            x += step
                        }
                    }
                    .stroke(lineColor, lineWidth: lineWidth)
                }
            }
        }
    }

    private func overlaps(_ aStart: Date, _ aEnd: Date, _ bStart: Date, _ bEnd: Date) -> Bool {
        max(aStart, bStart) < min(aEnd, bEnd)
    }

    private func paddedWindow() -> (start: Date, end: Date)? {
        let requestedDuration = endDate.timeIntervalSince(startDate)
        guard requestedDuration > 0 else { return nil }

        // Mirrors backend availability range:
        // start = requested start - 1h; end = requested start + (numDays + 1) days.
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

        return collapsed.map {
            AvailabilitySegment(start: $0.start, end: $0.end, state: $0.state)
        }
    }

    @ViewBuilder
    private var availabilityBar: some View {
        if let window = paddedWindow() {
            let segments = makeAvailabilitySegments()
            let totalDuration = window.end.timeIntervalSince(window.start)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(availabilityBarTrackColor)
                    Capsule()
                        .stroke(availabilityBarBorderColor, lineWidth: availabilityBarBorderWidth)

                    // Draw hatch/gray segments first.
                    ForEach(segments) { segment in
                        if segment.state == .unavailableOutsideRequest {
                            let segmentOffset = CGFloat(segment.start.timeIntervalSince(window.start) / totalDuration) * geo.size.width
                            let segmentWidth = max(
                                1,
                                CGFloat(segment.end.timeIntervalSince(segment.start) / totalDuration) * geo.size.width
                            )
                            DiagonalHatchFill(
                                backgroundColor: availabilityColorUnavailableOutsideRequest,
                                lineColor: availabilityHatchLineColor,
                                lineWidth: availabilityHatchLineWidth,
                                lineSpacing: availabilityHatchSpacing
                            )
                            .frame(width: segmentWidth, height: geo.size.height)
                            .offset(x: segmentOffset)
                        }
                    }

                    // Draw requested segments on top so hatch never overlays them.
                    ForEach(segments) { segment in
                        if segment.state == .requestedAvailable || segment.state == .requestedUnavailable {
                            let segmentOffset = CGFloat(segment.start.timeIntervalSince(window.start) / totalDuration) * geo.size.width
                            let segmentWidth = max(
                                1,
                                CGFloat(segment.end.timeIntervalSince(segment.start) / totalDuration) * geo.size.width
                            )
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
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(vehicle.vehicle.make) \(vehicle.vehicle.model)")
                        Text(vehicle.vehicle.name)
                            .fontWeight(.light)
                    }
                    Text("\(VeygoCurrencyStandard.shared.dollarFormatter.string(from: (vehicle.vehicle.msrpFactor.value * apartment.durationRate.value * rateOffer.multiplier.value) as NSDecimalNumber)!)/hr")
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
                Text(loc.location.name)
                    .font(.title3)
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
    @Binding var path: [HomeDestination]
    @Binding var selectedLocation: Location.ID?
    @Binding var selectedVehicle: PublishRenterVehicle.ID?
    let locations: [LocationWithVehicles]
    let apartment: Apartment
    let startDate: Date
    let endDate: Date
    let rateOffer: RateOffer
    let taxes: [Tax]

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
                                        path.append(.vehicleDetails(
                                            vehicle: v,
                                            location: loc.location,
                                            apartment: apartment,
                                            rateOffer: rateOffer,
                                            taxes: taxes,
                                            startDate: startDate,
                                            endDate: endDate
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
