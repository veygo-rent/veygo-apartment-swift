//
//  CreditCardView.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/24/25.
//
//

import SwiftUI

struct CreditCardView: View {
    
    @State private var sensoryFeedbackTrigger: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @EnvironmentObject var session: UserSession
    @Binding var cards: [PublishPaymentMethod]
    @State private var expandedCardID: PublishPaymentMethod.ID? = nil
    
    @Binding var path: [SettingDestination]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassEffectContainer {
                List {
                    ForEach(cards) { card in
                        CreditCardRow(
                            card: card,
                            isExpanded: expandedCardID == card.id,
                            onTap: {
                                sensoryFeedbackTrigger.toggle()
                                withAnimation(.easeInOut) {
                                    expandedCardID = (expandedCardID == card.id) ? nil : card.id
                                }
                            }
                        )
                        .listRowSeparator(.hidden, edges: .all)
                        .listRowBackground(Color("MainBG"))
                    }
                    .onDelete { indexSet in
                        Task {
                            await ApiCallActor.shared.appendApi { token, userId in
                                await deleteCardAsync(token, userId, at: indexSet)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await loadCardsAsync(token, userId)
                        }
                    }
                }
            }

            Spacer()

            PrimaryButton(text: "Add Card") {
                path.append(.addCard)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationTitle(Text("My Cards"))
        .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
        .onAppear {
            Task {
                await ApiCallActor.shared.appendApi { token, userId in
                    await loadCardsAsync(token, userId)
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
        .sensoryFeedback(.selection, trigger: sensoryFeedbackTrigger)
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
                        self.cards = decodedBody
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
    
    @ApiCallActor func deleteCardAsync (_ token: String, _ userId: Int, at offsets: IndexSet) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                let cards = await cards
                guard cards.count > 0, let index = offsets.first else {
                    await MainActor.run {
                        alertTitle = "Internal Error"
                        alertMessage = "Trying to delete a card that doesn't exist"
                        showAlert = true
                    }
                    return .doNothing
                }
                let cardToDelete = cards[index]
                
                let request = veygoCurlRequest(
                    url: "/api/v1/payment-method/delete/\(cardToDelete.id)",
                    method: .delete,
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
                    let _ = await MainActor.run {
                        self.cards.remove(at: index)
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

private struct CreditCardRow: View {
    
    private func convertDateToString(_ date: Date?) -> String {
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "Month D, Yr"
            return formatter.string(from: date)
        } else {
            return "Never"
        }
    }
    
    let card: PublishPaymentMethod
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 16) {
                cardBrandImage(for: card.network)
                    .frame(width: 64, height: 64)
                    .cornerRadius(4)

                VStack(alignment: .leading, spacing: 2) {
                    Text(card.nickname ?? card.maskedCardNumber)
                        .font(.headline)
                        .foregroundStyle(Color("TextBlackPrimary"))
                    Text("Exp: \(card.expiration)")
                        .font(.subheadline)
                        .foregroundStyle(Color("FootNote"))
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .onTapGesture {
                onTap()
            }

            if isExpanded {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Card Number: \(card.maskedCardNumber)")
                        .font(.subheadline)
                        .foregroundStyle(Color("TextBlackSecondary"))
                    Text("Last Used: \(convertDateToString(card.lastUsedDateTime))")
                        .font(.subheadline)
                        .foregroundStyle(Color("TextBlackSecondary"))
                }
            }
        }
        .padding()
        .background(Color("CardBG"), ignoresSafeAreaEdges: .all)
        .cornerRadius(12)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
    }
}

@ViewBuilder
func cardBrandImage(for brand: String) -> some View {
    let lowercased = brand.lowercased()
    let knownBrands = [ "amex", "mastercard", "visa", "discover" ]

    if knownBrands.contains(lowercased) {
        Image(lowercased)
            .resizable()
    } else {
        Image(systemName: "creditcard")
            .resizable()
            .frame(width: 32, height: 22)
            .foregroundColor(.primaryButtonBg)
    }
}


