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
    
    @State private var locationManager = CLLocationManager()
    
    @Binding var path: [HomeDestination]
    
    @EnvironmentObject var session: UserSession
    
    @Binding var startDate: Date
    @Binding var endDate: Date
    var apartment: Apartment
    
    @State private var selectedLocation: Location.ID? = nil
    @State private var locations: [LocationWithVehicles] = []
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    var body: some View {
        Map(position: $cameraPosition, selection: $selectedLocation) {
            UserAnnotation()
            ForEach(Array(locations.enumerated()), id: \.element.id) { locationIndex, location in
                Marker(location.location.name, systemImage: "car", coordinate: CLLocationCoordinate2D(latitude: location.location.latitude, longitude: location.location.longitude))
                    .tag(location.id)
                    .tint(.purple)
            }
        }
        .onAppear(perform: {
            locationManager.requestWhenInUseAuthorization()
        })
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .all, showsTraffic: true))
        .mapControls {
            MapCompass()
            if locationManager.authorizationStatus == .authorizedWhenInUse {
                MapUserLocationButton()
            }
        }
        .onChange(of: selectedLocation) { _, newValue in
            guard let sel = newValue,
                  let loc = locations.first(where: { $0.id == sel }) else { return }
            let coord = CLLocationCoordinate2D(latitude: loc.location.latitude, longitude: loc.location.longitude)
            withAnimation(.easeInOut(duration: 0.35)) {
                cameraPosition = .camera(MapCamera(centerCoordinate: coord, distance: 1600, heading: 0, pitch: 0))
            }
        }
        .sheet(
            isPresented: Binding(
                get: { selectedLocation != nil },
                set: { if !$0 { selectedLocation = nil } }
            )
        ) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(Array(locations.enumerated()), id: \.element.id) { locationIndex, location in
                        VStack (alignment: .leading) {
                            HStack {
                                Text(location.location.name)
                                    .font(.title3)
                                    .padding(.leading)
                                if let duration = location.duration {
                                    Text("\(String(format: "%.1f", duration)) hr")
                                }
                            }
                            HStack {
                                ForEach(Array(location.vehicles.enumerated()), id: \.element.id) { vehicleIndex, vehicle in
                                    VStack {
                                        HStack {
                                            VStack (alignment: .leading, spacing: 12) {
                                                Text("\(vehicle.vehicle.make) \(vehicle.vehicle.model)")
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
                                    }
                                    .padding()
                                    .frame(width: 340)
                                    .background {
                                        Color("CardBG")
                                    }
                                    .cornerRadius(18)
                                    .shadow(radius: 0.5)
                                }
                            }
                        }
                        .padding(.leading, 16)
                        .padding(.trailing, (locationIndex == locations.count - 1) ? 16 : 0)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $selectedLocation)
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, alignment: .bottom)
            .presentationDetents([.height(280)])
            .presentationBackgroundInteraction(.enabled)
        }
        .animation(.easeInOut(duration: 0.5), value: selectedLocation)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if clearUserTriggered {
                    session.user = nil
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
            Task {
                await ApiCallActor.shared.appendApi { token, userId in
                    await loadLocationsAsync(token, userId)
                }
                if [.authorizedWhenInUse, .authorizedAlways].contains(locationManager.authorizationStatus) {
                    // Try to use the last known location. For one-shot fetching, you’d set a delegate and call requestLocation().
                    if let userCoord = locationManager.location?.coordinate {
                        for i in locations.indices {
                            let dest = CLLocationCoordinate2D(latitude: locations[i].location.latitude, longitude: locations[i].location.longitude)
                            do {
                                let seconds = try await walkingETASeconds(from: userCoord, to: dest)
                                await MainActor.run {
                                    locations[i].duration = seconds
                                }
                            } catch error {
                                print(error.localizedDescription)
                            }
                        }
                    }
                }
            }
        }
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
                    await MainActor.run {
                        self.locations = decodedBody.vehicles
                    }
                    return .renewSuccessful(token: token)
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
}


func walkingETASeconds(from: CLLocationCoordinate2D,
                       to: CLLocationCoordinate2D) async throws -> TimeInterval {
    let src = MKMapItem(placemark: MKPlacemark(coordinate: from))
    let dst = MKMapItem(placemark: MKPlacemark(coordinate: to))

    let req = MKDirections.Request()
    req.source = src
    req.destination = dst
    req.transportType = .walking
    req.requestsAlternateRoutes = false

    let directions = MKDirections(request: req)
    let response = try await directions.calculate()
    // Take the first route (there can be several)
    guard let route = response.routes.first else {
        throw NSError(domain: "Directions", code: 0, userInfo: [NSLocalizedDescriptionKey: "No walking route"])
    }
    return route.expectedTravelTime // seconds
}
