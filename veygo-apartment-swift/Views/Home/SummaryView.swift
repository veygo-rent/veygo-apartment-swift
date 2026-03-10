//
//  SummaryView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 3/9/26.
//

import SwiftUI
import MapKit

struct SummaryView: View {
    
    @EnvironmentObject var session: UserSession
    
    @State private var paymentMethods: [PublishPaymentMethod] = []
    @State private var selectedPaymentMethod: PublishPaymentMethod?
    
    @State private var isLoadingPM: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @Binding var path: [HomeDestination]
    
    let startDate: Date
    let endDate: Date
    
    let vehicle: PublishRenterVehicle
    let apartment: Apartment
    let location: Location
    let promo: PublishPromo?
    let mileagePackage: MileagePackage?
    
    var body: some View {
        VStack {
            if let _ = session.user {
                List {
                    Image(.tempVehicle)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 130)
                        .clipped()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.mainBG)
                    VStack (alignment: .leading, spacing: 16) {
                        Text("\(vehicle.make) \(vehicle.model)")
                            .foregroundStyle(Color.textBlackSecondary)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("\(vehicle.licenseState) \(vehicle.licenseNumber) \(vehicle.name)")
                            .foregroundStyle(Color.textBlackPrimary)
                            .font(.subheadline)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.mainBG)
                    
                    VStack (alignment: .leading, spacing: 16) {
                        Text("Itinerary")
                            .foregroundStyle(Color.textBlackSecondary)
                            .font(.title2)
                            .fontWeight(.bold)
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundStyle(Color.accent)
                            Text("\(apartment.name) - \(location.name)")
                                .foregroundStyle(Color.textBlackPrimary)
                        }
                        .font(.subheadline)
                        HStack {
                            Image(systemName: "clock.badge.fill")
                                .foregroundStyle(Color.textLink)
                            Text("\(apartment.localizedDate(for: startDate))")
                                .foregroundStyle(Color.textBlackPrimary)
                        }
                        .font(.subheadline)
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(Color.textLink)
                            Text("\(apartment.localizedDate(for: endDate))")
                                .foregroundStyle(Color.textBlackPrimary)
                        }
                        .font(.subheadline)
                        Map(
                            initialPosition: .region(
                                MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(
                                        latitude: location.latitude,
                                        longitude: location.longitude
                                    ),
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                            ),
                            interactionModes: []
                        ) {
                            Marker(
                                "Pickup Location",
                                coordinate: CLLocationCoordinate2D(
                                    latitude: location.latitude,
                                    longitude: location.longitude
                                )
                            ).tint(.purple)
                        }
                        .frame(height: 160)
                        .cornerRadius(16)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.mainBG)
                    
                    VStack (alignment: .leading, spacing: 16) {
                        Text("Payment Info")
                            .foregroundStyle(Color.textBlackSecondary)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // TODO: Display Selected card
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.mainBG)
                }
                .scrollIndicators(.hidden)
                .listStyle(.plain)
                PrimaryButton(text: "Book Trip") {
                    
                }
                .padding()
                .alert(alertTitle, isPresented: $showAlert) {
                    Button("OK") {
                        if clearUserTriggered {
                            session.user = nil
                        }
                    }
                } message: {
                    Text(alertMessage)
                }
                .onAppear {
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await loadCardsAsync(token, userId)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .frame(maxWidth: .infinity)
        .navigationTitle(Text("Trip Summary"))
        .background(Color.mainBG, ignoresSafeAreaEdges: .all)
    }
    
    @ApiCallActor func loadCardsAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                let request = veygoCurlRequest(
                    url: "/api/v1/payment-method/get",
                    method: .get,
                    headers: [
                        "auth": "\(token)$\(userId)"
                    ]
                )
                await MainActor.run {
                    isLoadingPM = true
                }
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
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode([PublishPaymentMethod].self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        self.paymentMethods = decodedBody
                        isLoadingPM = false
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
}

private struct SelectPaymentCardView: View {
    
    @Binding var paymentMethods: [PublishPaymentMethod]
    @Binding var selectedPaymentMethod: PublishPaymentMethod?
    
    var body: some View {
        Text("Select Payment Card")
    }
}
