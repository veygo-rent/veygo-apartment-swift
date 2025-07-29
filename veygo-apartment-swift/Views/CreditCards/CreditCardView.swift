//
//  CreditCardView.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/24/25.
//
//

import SwiftUI

struct CreditCardView: View {
    @EnvironmentObject var session: UserSession
    @State private var cards: [PublishPaymentMethod] = []
    @State private var expandedCardID: Int? = nil
    @State private var navigateToAddCard = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Cards")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal)

                List {
                    ForEach(cards) { card in
                        CreditCardRow(
                            card: card,
                            isExpanded: expandedCardID == card.id,
                            onTap: {
                                withAnimation {
                                    expandedCardID = (expandedCardID == card.id) ? nil : card.id
                                }
                            }
                        )
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: deleteCard)
                }
                .listStyle(PlainListStyle())

                Spacer()

                PrimaryButton(text: "Add Card") {
                    navigateToAddCard = true
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationDestination(isPresented: $navigateToAddCard) {
                FullStripeCardEntryView()
            }
            .onAppear {
                loadCards()
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    func loadCards() {
        let request = veygoCurlRequest(
            url: "/api/v1/payment-method/get",
            method: "GET",
            headers: [
                "auth": "\(token)$\(userId)"
            ]
        )

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showAlert = true
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    alertMessage = "Invalid response"
                    showAlert = true
                    return
                }

                guard let data = data else {
                    alertMessage = "Empty response"
                    showAlert = true
                    return
                }

                switch httpResponse.statusCode {
                case 200:
                    if let newToken = extractToken(from: response) {
                        self.token = newToken
                    }

                    do {
                        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]

                        guard let paymentArray = jsonObject?["payment_methods"] else {
                            alertMessage = "No payment_methods found"
                            showAlert = true
                            return
                        }

                        let methodsData = try JSONSerialization.data(withJSONObject: paymentArray)

                        let decoded = try VeygoJsonStandard.shared.decoder.decode([PublishPaymentMethod].self, from: methodsData)

                        self.cards = decoded
                    } catch {
                        print("Decode error: \(error)")
                        alertMessage = "Failed to parse payment_methods"
                        showAlert = true
                    }

                case 401:
                    alertMessage = "Session expired. Please log in again."
                    session.clear()
                    showAlert = true
                case 500:
                    alertMessage = "Server error. Try again later."
                    showAlert = true
                default:
                    let rawText = String(data: data, encoding: .utf8) ?? "Unknown error"
                    alertMessage = "Error: \(rawText)"
                    showAlert = true
                }
            }
        }.resume()
    }

    func deleteCard(at offsets: IndexSet) {
        guard cards.count > 1 else {
            alertMessage = "You must have at least one card on file."
            showAlert = true
            return
        }

        guard let index = offsets.first else { return }
        let cardToDelete = cards[index]

        let requestBody: [String: Any] = [
            "card_id": cardToDelete.id
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            alertMessage = "Failed to encode delete request"
            showAlert = true
            return
        }

        var request = veygoCurlRequest(
            url: "/api/v1/payment-method/delete",
            method: "POST",
            headers: [
                "auth": "\(token)$\(userId)",
                "user-agent": "iOS-App"
            ]
        )
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showAlert = true
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    alertMessage = "Invalid response"
                    showAlert = true
                    return
                }

                guard let data = data else {
                    alertMessage = "Empty response"
                    showAlert = true
                    return
                }

                switch httpResponse.statusCode {
                case 200:
                    if let newToken = extractToken(from: response) {
                        self.token = newToken
                    }

                    do {
                        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        guard let paymentArray = jsonObject?["payment_methods"] else {
                            alertMessage = "No payment_methods found"
                            showAlert = true
                            return
                        }

                        let methodsData = try JSONSerialization.data(withJSONObject: paymentArray)
                        let decoded = try VeygoJsonStandard.shared.decoder.decode([PublishPaymentMethod].self, from: methodsData)
                        self.cards = decoded
                    } catch {
                        alertMessage = "Failed to parse updated card list"
                        showAlert = true
                    }

                case 406:
                    alertMessage = "Invalid payment method."
                    showAlert = true
                case 401:
                    alertMessage = "Session expired. Please log in again."
                    session.clear()
                    showAlert = true
                case 500:
                    alertMessage = "Server error. Try again later."
                    showAlert = true
                default:
                    let rawText = String(data: data, encoding: .utf8) ?? "Unknown error"
                    alertMessage = "Error: \(rawText)"
                    showAlert = true
                }
            }
        }.resume()
    }
}

#Preview {
    CreditCardView()
        .environmentObject(UserSession())
}
