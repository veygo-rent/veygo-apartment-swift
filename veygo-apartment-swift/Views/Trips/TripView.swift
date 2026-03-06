//
//  Plans.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/18/25.
//
import SwiftUI
import MapKit

struct TripView: View {
    @EnvironmentObject var session: UserSession
    
    @State private var upcomingReservations: [TripInfo] = []
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @State private var isLoading: Bool = true
    
    @Binding var selectedTab: RootDestination
    public var body: some View {
        if let _ = session.user {
            NavigationStack {
                List {
                    NavigationLink {
                        HistoryView()
                    } label: {
                        HStack {
                            Text("History and Receipts")
                                .foregroundStyle(Color.accentColor)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.accentColor)
                        }
                        .padding()
                        .background(Color.cardBG)
                        .cornerRadius(12)
                    }
                    .navigationLinkIndicatorVisibility(.hidden)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.mainBG)
                    
                    if upcomingReservations.isEmpty {
                        VStack (alignment: .center, spacing: 16) {
                            Text("Want to start a new reservation?")
                                .foregroundStyle(Color.textBlackPrimary)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            PrimaryButton(text: "Make a reservation") {
                                selectedTab = .home
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 22)
                        .overlay(content: {
                            if isLoading {
                                LoadingView().cornerRadius(12)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.footNote.opacity(0.5), lineWidth: 1)
                            }
                        })
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.mainBG)
                    } else {
                        Text("Your Upcoming \(upcomingReservations.count == 1 ? "Trip" : "Trips")")
                            .font(.title)
                            .fontWeight(.bold)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.mainBG)
                        ForEach(upcomingReservations) { rsvp in
                            GlassEffectContainer {
                                NavigationLink {
                                    UpcomingReservationDetailedView(rsvp: rsvp.agreement)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Text("RSVP")
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(Color.textBlackPrimary)
                                                Text("#\(rsvp.agreement.confirmation)")
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(Color.textLink)
                                            }
                                            Text("\(rsvp.localizedStartDate())")
                                                .font(.callout)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(Color.textBlackSecondary)
                                            Text("Location: \(rsvp.locationName)")
                                                .font(.callout)
                                                .foregroundStyle(Color.textBlackSecondary)
                                            Text("Vehicle: \(rsvp.vehicleName)")
                                                .font(.callout)
                                                .foregroundStyle(Color.textBlackSecondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                    .padding()
                                    .background(Color.cardBG, ignoresSafeAreaEdges: .all)
                                    .cornerRadius(12)
                                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                                }
                                .navigationLinkIndicatorVisibility(.hidden)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.mainBG)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .listStyle(.plain)
                .scrollIndicators(.hidden)
                .background(Color.mainBG, ignoresSafeAreaEdges: .all)
                .navigationTitle(Text("Trips"))
                .onAppear {
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await loadCurrentTripAsync(token, userId)
                        }
                    }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") {
                    if clearUserTriggered {
                        session.user = nil
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    @ApiCallActor func loadCurrentTripAsync(_ token: String, _ userId: Int) async -> ApiTaskResponse {
        let request = veygoCurlRequest(
            url: "/api/v1/agreement/upcoming",
            method: .get,
            headers: [
                "auth": "\(token)$\(userId)"
            ]
        )
        do {
            await MainActor.run {
                isLoading = true
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
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode([TripInfo].self, from: data) else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                await MainActor.run {
                    upcomingReservations = decodedBody
                    isLoading = false
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
            case 500:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E500
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

private struct UpcomingReservationDetailedView: View {
    @EnvironmentObject var session: UserSession
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @State private var details: TripDetailedInfo?
    
    let rsvp: Agreement
    var body: some View {
        if let _ = session.user {
            List {
                if let details = details {
                    HStack {
                        Text("Confirmation #:")
                            .foregroundStyle(Color.textBlackSecondary)
                            .font(.subheadline)
                        Text("\(rsvp.confirmation)")
                            .foregroundStyle(Color.accent)
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.mainBG)
                    Image(.tempVehicle)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 130)
                        .clipped()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.mainBG)
                    VStack (alignment: .leading, spacing: 16) {
                        Text("\(details.vehicle.make) \(details.vehicle.model)")
                            .foregroundStyle(Color.textBlackSecondary)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("\(details.vehicle.licenseState) \(details.vehicle.licenseNumber) \(details.vehicle.name)")
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
                            Text("\(details.apartment.name) - \(details.location.name)")
                                .foregroundStyle(Color.textBlackPrimary)
                        }
                        .font(.subheadline)
                        HStack {
                            Image(systemName: "clock.badge.fill")
                                .foregroundStyle(Color.textLink)
                            Text("\(details.localizedStartDate())")
                                .foregroundStyle(Color.textBlackPrimary)
                        }
                        .font(.subheadline)
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(Color.textLink)
                            Text("\(details.localizedEndDate())")
                                .foregroundStyle(Color.textBlackPrimary)
                        }
                        .font(.subheadline)
                        Map(
                            initialPosition: .region(
                                MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(
                                        latitude: details.location.latitude,
                                        longitude: details.location.longitude
                                    ),
                                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                )
                            ),
                            interactionModes: []
                        ) {
                            Marker(
                                "Pickup Location",
                                coordinate: CLLocationCoordinate2D(
                                    latitude: details.location.latitude,
                                    longitude: details.location.longitude
                                )
                            )
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
                        HStack (spacing: 16) {
                            cardBrandImage(for: details.paymentMethod.network)
                                .frame(width: 64, height: 64)
                                .cornerRadius(4)
                            VStack (alignment: .leading, spacing: 4) {
                                Text(details.paymentMethod.nickname ?? details.paymentMethod.maskedCardNumber)
                                    .foregroundStyle(Color.textBlackPrimary)
                                Text("Expires: \(details.paymentMethod.expiration)")
                                    .foregroundStyle(Color.textBlackSecondary)
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.mainBG)
                }
            }
            .frame(maxWidth: .infinity)
            .listStyle(.plain)
            .scrollIndicators(.hidden)
            .background(Color.mainBG, ignoresSafeAreaEdges: .all)
            .navigationTitle(Text("Trip Summary"))
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
                        await loadDetailedTripAsync(token, userId)
                    }
                }
            }
        }
    }
    
    @ApiCallActor func loadDetailedTripAsync(_ token: String, _ userId: Int) async -> ApiTaskResponse {
        let request = veygoCurlRequest(
            url: "/api/v1/agreement/\(rsvp.confirmation)",
            method: .get,
            headers: [
                "auth": "\(token)$\(userId)"
            ]
        )
        do {
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
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(TripDetailedInfo.self, from: data) else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                await MainActor.run {
                    details = decodedBody
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
            case 500:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E500
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
