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
}


struct FindCarView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @Binding var path: [HomeDestination]
    
    @EnvironmentObject var session: UserSession
    
    @Binding var startDate: Date
    @Binding var endDate: Date
    var apartmentId: Apartment.ID
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.4237, longitude: -86.9212),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var selectedLocation: Location.ID? = nil
    @State private var locations: [LocationWithVehicles] = []
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    var body: some View {
        ZStack (alignment: .bottom) {
            Map(coordinateRegion: $region, annotationItems: locations) { location in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.location.latitude, longitude: location.location.longitude)) {
                    Button(action: {
                        withAnimation {
                            region.center = CLLocationCoordinate2D(latitude: location.location.latitude, longitude: location.location.longitude)
                            region.span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                            selectedLocation = location.id
                        }
                    }) {
                        Image("Pin")
                            .resizable()
                            .frame(width: 48, height: 48)
                    }
                }
            }
            .ignoresSafeArea(.container, edges: [.bottom, .top])
            .simultaneousGesture(
                TapGesture().onEnded {
                    selectedLocation = nil
                }
            )

            if let selected = selectedLocation {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 20) {
                        ForEach(locations) { location in
                            VStack (alignment: .leading) {
                                Text(location.location.name)
                                HStack {
                                    ForEach(location.vehicles) { vehicle in
                                        VStack {
                                            Text("Name: \(vehicle.vehicle.name)")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $selectedLocation)
                .frame(height: 300)
                .background(.ultraThinMaterial)
                .frame(maxWidth: .infinity, alignment: .bottom)
            }
        }
        .navigationTitle(formattedDateRange)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(
            .thinMaterial,
            for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar(content: {
            if #unavailable(iOS 26) {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        path.removeLast()
                    }) {
                        BackButton()
                    }
                }
            }
        })
        .modifier(BackButtonHiddenModifier())
        .onAppear {
            Task {
                await ApiCallActor.shared.appendApi { token, userId in
                    let result = await loadLocationsAsync(token, userId)
                    await print(locations)
                    return result
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
                    "apartment_id": apartmentId
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

private struct VehicleCard: View {
    let vehicle: PublishVehicle
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(vehicle.name)")
                .font(.subheadline)
                .fontWeight(.medium)
            // Add any other fields you want to show here (e.g., plate, model)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
