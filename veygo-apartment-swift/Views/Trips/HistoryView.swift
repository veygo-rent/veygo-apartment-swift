//
//  HistoryView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 3/3/26.
//

import SwiftUI

struct HistoryView: View {
    
    @EnvironmentObject var session: UserSession
    
    @State private var pastAgreements: [Agreement]? = nil
    
    @State private var isLoading: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    var body: some View {
        List {
            if let pastAgreements {
                if pastAgreements.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No past rentals yet")
                            .font(.headline)
                            .foregroundStyle(Color.textBlackPrimary)
                        Text("Completed trips and receipts will show here.")
                            .font(.subheadline)
                            .foregroundStyle(Color.textBlackSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBG)
                    .cornerRadius(12)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.mainBG)
                } else {
                    ForEach(pastAgreements) { agreement in
                        agreementCard(for: agreement)
                    }
                }
            } else {
                ForEach(0..<3, id: \.self) { _ in
                    agreementCard(for: nil)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .navigationTitle(Text("Past Rentals"))
        .scrollContentBackground(.hidden)
        .background(Color.mainBG, ignoresSafeAreaEdges: .all)
        .onAppear {
            Task {
                await ApiCallActor.shared.appendApi { token, userId in
                    await loadPastRentalsAsync(token, userId)
                }
            }
        }
        .refreshable {
            Task {
                await ApiCallActor.shared.appendApi { token, userId in
                    await loadPastRentalsAsync(token, userId)
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
    
    @ViewBuilder
    func agreementCard(for agreement: Agreement?) -> some View {
        let pickupTime = agreement?.actualPickupTime ?? agreement?.rsvpPickupTime
        let dropOffTime = agreement?.actualDropOffTime ?? agreement?.rsvpDropOffTime
        let statusText: String = {
            guard let agreement else { return "Rental" }
            if agreement.actualPickupTime == nil {
                return "No Show"
            }
            if agreement.status == .rental, agreement.actualDropOffTime != nil {
                return "Completed"
            }
            return agreement.status.rawValue
        }()
        
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("RSVP")
                    .fontWeight(.bold)
                    .foregroundStyle(agreement == nil ? Color.clear : Color.textBlackPrimary)
                Text("#\(agreement?.confirmation ?? "ABCD-1234")")
                    .fontWeight(.semibold)
                    .foregroundStyle(agreement == nil ? Color.clear : Color.textLink)
            }
            Text("Pickup: \(pickupTime.map { VeygoDatetimeStandard.shared.formattedDateTime($0) } ?? "Mar 20, 9:00 AM")")
                .font(.callout)
                .foregroundStyle(agreement == nil ? Color.clear : Color.textBlackSecondary)
            Text("Dropoff: \(dropOffTime.map { VeygoDatetimeStandard.shared.formattedDateTime($0) } ?? "Mar 21, 9:00 AM")")
                .font(.callout)
                .foregroundStyle(agreement == nil ? Color.clear : Color.textBlackSecondary)
            HStack {
                Text("Status")
                    .font(.caption)
                    .foregroundStyle(agreement == nil ? Color.clear : Color.textBlackSecondary)
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(agreement == nil ? Color.clear : Color.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(agreement == nil ? Color.clear : Color.accentColor.opacity(0.35), lineWidth: 1)
                    }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBG)
        .cornerRadius(12)
        .overlay {
            if agreement == nil {
                LoadingView()
                    .cornerRadius(12)
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)
    }
    
    @ApiCallActor func loadPastRentalsAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                let request = veygoCurlRequest(
                    url: "/api/v1/agreement/past",
                    method: .get,
                    headers: [
                        "auth": "\(token)$\(userId)"
                    ]
                )
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
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode([Agreement].self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        self.pastAgreements = decodedBody
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
