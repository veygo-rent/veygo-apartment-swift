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
    
    var pricingStandard: VeygoPricingStandard { VeygoPricingStandard(apartment: apartment, vehicle: vehicle) }
    
    var body: some View {
        VStack {
            if let _ = session.user {
                GlassEffectContainer {
                    ZStack (alignment: .bottom) {
                        List {
                            Image(.tempVehicle)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 300, height: 130)
                                .clipped()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.mainBG)
                            
                            /// Vehicle Detail Section
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
                            
                            /// Itinerary Section
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
                            
                            /// Mileage Option Section
                            VStack (alignment: .leading, spacing: 16) {
                                Text("Mileage Option")
                                    .foregroundStyle(Color.textBlackSecondary)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                HStack {
                                    Image(systemName: "map.fill")
                                        .foregroundStyle(Color.accent)
                                    Text("^[Included distance: \(10 + (mileagePackage?.miles ?? 0)) mile](inflect: true)")
                                        .foregroundStyle(Color.textBlackPrimary)
                                }
                                .font(.subheadline)
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundStyle(Color.textLink)
                                    Text("\(pricingStandard.perMileSubtitle())")
                                        .foregroundStyle(Color.textBlackPrimary)
                                }
                                .font(.subheadline)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.mainBG)
                            
                            /// Payment Info Section
                            VStack (alignment: .leading, spacing: 16) {
                                Text("Payment Info")
                                    .foregroundStyle(Color.textBlackSecondary)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                NavigationLink {
                                    SelectPaymentCardView(
                                        paymentMethods: $paymentMethods,
                                        selectedPaymentMethod: $selectedPaymentMethod
                                    )
                                } label: {
                                    HStack(spacing: 16) {
                                        cardBrandImage(for: selectedPaymentMethod?.network ?? "")
                                            .frame(width: 48, height: 48)
                                            .cornerRadius(4)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(selectedPaymentMethod?.nickname ?? selectedPaymentMethod?.maskedCardNumber ?? "Select payment card")
                                                .foregroundStyle(Color.textBlackPrimary)
                                                .font(.subheadline)
                                            
                                            if let selectedPaymentMethod {
                                                Text("Expires: \(selectedPaymentMethod.expiration)")
                                                    .foregroundStyle(Color.textBlackSecondary)
                                                    .font(.footnote)
                                            } else {
                                                Text(isLoadingPM ? "Loading cards..." : "Tap to choose a card")
                                                    .foregroundStyle(Color.footNote)
                                                    .font(.footnote)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(Color.footNote)
                                    }
                                    .padding()
                                    .background(Color.cardBG)
                                    .cornerRadius(12)
                                    .glassEffect(.identity, in: .rect(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .navigationLinkIndicatorVisibility(.hidden)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.mainBG)
                            
                            /// Price Details
                            VStack (alignment: .leading, spacing: 16) {
                                Text("Price Details")
                                    .foregroundStyle(Color.textBlackSecondary)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                HStack {
                                    Image(systemName: "map.fill")
                                        .foregroundStyle(Color.accent)
                                    Text("^[Included distance: \(10 + (mileagePackage?.miles ?? 0)) mile](inflect: true)")
                                        .foregroundStyle(Color.textBlackPrimary)
                                }
                                .font(.subheadline)
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundStyle(Color.textLink)
                                    Text("\(pricingStandard.perMileSubtitle())")
                                        .foregroundStyle(Color.textBlackPrimary)
                                }
                                .font(.subheadline)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.mainBG)
                            .padding(.bottom, 80)
                        }
                        .scrollIndicators(.hidden)
                        .listStyle(.plain)
                        PrimaryButton(text: "Book Trip") {
                            
                        }
                        .disabled(selectedPaymentMethod == nil)
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
                        if let selectedPaymentMethod,
                           !decodedBody.contains(where: { $0.id == selectedPaymentMethod.id }) {
                            self.selectedPaymentMethod = decodedBody.first
                        } else if self.selectedPaymentMethod == nil {
                            self.selectedPaymentMethod = decodedBody.first
                        }
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
    
    @EnvironmentObject var session: UserSession
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @Binding var paymentMethods: [PublishPaymentMethod]
    @Binding var selectedPaymentMethod: PublishPaymentMethod?
    
    @State private var isAddingNewCard: Bool = false
    
    var body: some View {
        VStack {
            List {
                if paymentMethods.isEmpty {
                    Text("No payment cards available.")
                        .foregroundStyle(Color.footNote)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.mainBG)
                } else {
                    ForEach(paymentMethods) { card in
                        Button {
                            selectedPaymentMethod = card
                            dismiss()
                        } label: {
                            HStack(spacing: 16) {
                                cardBrandImage(for: card.network)
                                    .frame(width: 48, height: 48)
                                    .cornerRadius(4)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.nickname ?? card.maskedCardNumber)
                                        .foregroundStyle(Color.textBlackPrimary)
                                        .font(.headline)
                                    Text("Exp: \(card.expiration)")
                                        .foregroundStyle(Color.footNote)
                                        .font(.subheadline)
                                }
                                
                                Spacer()
                                
                                if selectedPaymentMethod?.id == card.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.primaryButtonBg)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.mainBG)
                    }
                }
            }
            .listStyle(.plain)
            .onChange(of: isAddingNewCard, { oldValue, newValue in
                if !newValue {
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await loadCardsAsync(token, userId)
                        }
                    }
                }
            })
            PrimaryButton(text: "Add a New Card") {
                isAddingNewCard = true
            }
            .padding()
            .sheet(isPresented: $isAddingNewCard) {
                FullStripeCardEntryView()
            }

        }
        .navigationTitle("Select Payment Card")
        .navigationBarTitleDisplayMode(.large)
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
                        if let selectedPaymentMethod,
                           !decodedBody.contains(where: { $0.id == selectedPaymentMethod.id }) {
                            self.selectedPaymentMethod = decodedBody.first
                        } else if self.selectedPaymentMethod == nil {
                            self.selectedPaymentMethod = decodedBody.first
                        }
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
