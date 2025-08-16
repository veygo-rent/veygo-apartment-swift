//
//  FindCarView.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/1/25.
//

import SwiftUI
import MapKit

nonisolated private struct BlockedRange: Decodable {
    var startTime: Date
    var endTime: Date
}
nonisolated private struct VehicleWithBlockedDurations: Decodable, Identifiable {
    var vehicle: PublishVehicle
    var blockedDurations: [BlockedRange]
    var id: PublishVehicle.ID { vehicle.id }
}
nonisolated private struct LocationWithVehicles: Decodable, Identifiable {
    var location: Location
    var vehicles: [VehicleWithBlockedDurations]
    var id: Location.ID { location.id }
    var duration: TimeInterval? = nil
}


struct FindCarView: View {
    
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
    @State private var selectedVehicle: PublishVehicle.ID? = nil
    @State private var locations: [LocationWithVehicles] = []
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    @State private var savedPosition: MapCameraPosition? = nil
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    var body: some View {
        Map(position: $cameraPosition, selection: $selectedLocation) {
            UserAnnotation()
            ForEach(locations, id: \.id) { location in
                Marker(
                    location.location.name,
                    systemImage: "car",
                    coordinate: CLLocationCoordinate2D(
                        latitude: location.location.latitude,
                        longitude: location.location.longitude
                    )
                )
                .tag(location.id)
                .tint(.purple)
                .annotationSubtitles(.visible)
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
                guard let loc = locations.getItemBy(id: sel) else { return }
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
            LocationStripView(
                selectedLocation: $selectedLocation,
                selectedVehicle: $selectedVehicle,
                locations: locations,
                apartment: apartment,
                startDate: startDate,
                endDate: endDate
            )
            .presentationDetents([.height(280)])
            .presentationBackgroundInteraction(.enabled)
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
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(
            .ultraThinMaterial,
            for: .navigationBar)
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        selectedLocation = nil
                    }
                    path.removeLast()
                }) {
                    if #unavailable(iOS 26) {
                        BackButton()
                    } else {
                        Image(systemName: "chevron.left")
                    }
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
        guard !locations.isEmpty else { return nil }

        var minLat =  90.0, maxLat = -90.0
        var minLon = 180.0, maxLon = -180.0
        for l in locations {
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
                    nonisolated struct FetchSuccessBody: Decodable {
                        let vehicles: [LocationWithVehicles]
                    }
                    
                    let token = extractToken(from: response) ?? ""
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(FetchSuccessBody.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .renewSuccessful(token: token)
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
                        self.locations = decodedBody.vehicles
                    }
                    Task { await updateWalkingETAs() }
                    return .renewSuccessful(token: token)
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
                        return .renewSuccessful(token: token)
                    }
                    await MainActor.run {
                        alertTitle = "Invalid Request"
                        alertMessage = decodedBody.error
                        showAlert = true
                        backButtonTriggered = true
                    }
                    return .doNothing
                case 401:
                    await MainActor.run {
                        alertTitle = "Session Expired"
                        alertMessage = "Token expired, please login again"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
                case 405:
                    await MainActor.run {
                        alertTitle = "Internal Error"
                        alertMessage = "Method not allowed, please contact the developer dev@veygo.rent"
                        showAlert = true
                    }
                    return .doNothing
                default:
                    await MainActor.run {
                        alertTitle = "Application Error"
                        alertMessage = "Unrecognized response, make sure you are running the latest version"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
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
        guard [.authorizedWhenInUse, .authorizedAlways].contains(locationManager.authorizationStatus),
              let userCoord = locationManager.location?.coordinate else { return }

        // Compute ETAs and store in hours for display
        for i in locations.indices {
            let dest = CLLocationCoordinate2D(
                latitude: locations[i].location.latitude,
                longitude: locations[i].location.longitude
            )
            do {
                let seconds = try await walkingETASeconds(from: userCoord, to: dest)
                locations[i].duration = seconds / 60.0
            } catch {
                print(error.localizedDescription)
            }
        }
        
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
    let src = MKMapItem(placemark: MKPlacemark(coordinate: from))
    let dst = MKMapItem(placemark: MKPlacemark(coordinate: to))

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

private struct VehicleCardView: View {
    let vehicle: VehicleWithBlockedDurations
    let apartment: Apartment
    let startDate: Date
    let endDate: Date
    
    private struct HourlyBlock: Identifiable {
        let id = UUID()
        let hourStr: String
        let firstQtrWanted: Bool
        let secondQtrWanted: Bool
        let thirdQtrWanted: Bool
        let fourthQtrWanted: Bool
        let firstQtrTaken: Bool
        let secondQtrTaken: Bool
        let thirdQtrTaken: Bool
        let fourthQtrTaken: Bool
    }
    
    @ViewBuilder
    private func QuarterlyBlock(wanted: Bool, taken: Bool) -> some View {
        if wanted {
            if taken {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemRed))
                    .frame(width: 14, height: 16)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGreen))
                    .frame(width: 14, height: 16)
            }
        } else {
            if taken {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray))
                    .frame(width: 14, height: 16)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(lineWidth: 1)
                    .frame(width: 14, height: 16)
            }
        }
    }
    
    @ViewBuilder
    private func HourlyAvailability(availability: HourlyBlock) -> some View {
        VStack (alignment: .center) {
            HStack (spacing: 4) {
                QuarterlyBlock(wanted: availability.firstQtrWanted, taken: availability.firstQtrTaken)
                QuarterlyBlock(wanted: availability.secondQtrWanted, taken: availability.secondQtrTaken)
                QuarterlyBlock(wanted: availability.thirdQtrWanted, taken: availability.thirdQtrTaken)
                QuarterlyBlock(wanted: availability.fourthQtrWanted, taken: availability.fourthQtrTaken)
            }
            Text("\(availability.hourStr)").font(.caption)
        }
    }

    private func overlaps(_ aStart: Date, _ aEnd: Date, _ bStart: Date, _ bEnd: Date) -> Bool {
        max(aStart, bStart) < min(aEnd, bEnd)
    }

    private func makeFourHourBlocks() -> [HourlyBlock] {
        let cal = Calendar.current
        // Start at the floor of the startDate to the hour
        let comps = cal.dateComponents([.year,.month,.day,.hour], from: startDate)
        guard let hourStart = cal.date(from: comps) else { return [] }
        let hours: [Date] = [
            hourStart,
            cal.date(byAdding: .hour, value: 1, to: hourStart)!,
            cal.date(byAdding: .hour, value: 2, to: hourStart)!,
            cal.date(byAdding: .hour, value: 3, to: hourStart)!
        ]

        func quarterWanted(_ qStart: Date) -> Bool {
            let qEnd = cal.date(byAdding: .minute, value: 15, to: qStart)!
            return overlaps(qStart, qEnd, startDate, endDate)
        }
        func quarterTaken(_ qStart: Date) -> Bool {
            let qEnd = cal.date(byAdding: .minute, value: 15, to: qStart)!
            return vehicle.blockedDurations.contains { br in overlaps(qStart, qEnd, br.startTime, br.endTime) }
        }

        var blocks: [HourlyBlock] = []
        let df = DateFormatter(); df.dateFormat = "h a"

        for h in hours {
            let q1 = h
            let q2 = cal.date(byAdding: .minute, value: 15, to: h)!
            let q3 = cal.date(byAdding: .minute, value: 30, to: h)!
            let q4 = cal.date(byAdding: .minute, value: 45, to: h)!
            let block = HourlyBlock(
                hourStr: df.string(from: h),
                firstQtrWanted: quarterWanted(q1),
                secondQtrWanted: quarterWanted(q2),
                thirdQtrWanted: quarterWanted(q3),
                fourthQtrWanted: quarterWanted(q4),
                firstQtrTaken: quarterTaken(q1),
                secondQtrTaken: quarterTaken(q2),
                thirdQtrTaken: quarterTaken(q3),
                fourthQtrTaken: quarterTaken(q4)
            )
            blocks.append(block)
        }
        return blocks
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
                    Text("$\(String(format: "%.2f", vehicle.vehicle.msrpFactor * apartment.durationRate))/hr • $\(String(format: "%.2f", vehicle.vehicle.msrpFactor * apartment.durationRate * 7))/day")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("SecondaryButtonText"))
                    HStack {
                        Image(systemName: "fuelpump")
                        Text(" \(vehicle.vehicle.tankLevelPercentage)%")
                    }
                }
                Spacer()
                Image("carImg")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80)
            }
            HStack(spacing: 8) {
                ForEach(makeFourHourBlocks()) { hour in
                    HourlyAvailability(availability: hour)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(width: 340)
        .background { Color("CardBG") }
        .cornerRadius(18)
        .shadow(radius: 0.5)
    }
}

private struct LocationStripView: View {
    @Binding var selectedLocation: Location.ID?
    @Binding var selectedVehicle: PublishVehicle.ID?
    let locations: [LocationWithVehicles]
    let apartment: Apartment
    let startDate: Date
    let endDate: Date

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(Array(locations.enumerated()), id: \.element.id) { index, loc in
                    HStack {
                        ForEach(loc.vehicles, id: \.id) { v in
                            VStack (alignment: .leading) {
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
                                VehicleCardView(vehicle: v, apartment: apartment, startDate: startDate, endDate: endDate)
                            }
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
    }
}
