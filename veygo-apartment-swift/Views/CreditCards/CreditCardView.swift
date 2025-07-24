//
//  CreditCardView.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/24/25.
//
//
//import SwiftUI
//
//struct CreditCardView: View {
//    @State private var cards: [CreditCard] = []
//    @State private var expandedCardID: Int? = nil
//    @State private var navigateToAddCard = false
//
//    var body: some View {
//        NavigationStack {
//            VStack(alignment: .leading, spacing: 16) {
//                Text("Your Cards")
//                    .font(.title2)
//                    .bold()
//                    .padding(.horizontal)
//
//                List {
//                    ForEach(cards) { card in
//                        CreditCardRow(
//                            card: card,
//                            isExpanded: expandedCardID == card.id,
//                            onTap: {
//                                withAnimation {
//                                    expandedCardID = (expandedCardID == card.id) ? nil : card.id
//                                }
//                            }
//                        )
//                        .listRowBackground(Color.clear)
//                    }
//                    .onDelete(perform: deleteCard)
//                }
//                .listStyle(PlainListStyle())
//
//                Spacer()
//
//                PrimaryButton(text: "Add Card") {
//                            navigateToAddCard = true
//                }
//                .padding(.horizontal)
//                .padding(.bottom, 20)
//            }
//            .navigationDestination(isPresented: $navigateToAddCard) {
//                    FullStripeCardEntryView()
//            }
//            .onAppear {
//                loadCards()
//            }
//        }
//    }
//
//    func loadCards() {
//        // TODO: GET API
//        self.cards = [
//            CreditCard(
//                id: 1,
//                cardholderName: "Xinyi Guan",
//                maskedCardNumber: "**** **** **** 4242",
//                network: "Visa",
//                expiration: "12/26",
//                token: "tok_sample",
//                md5: "abc123",
//                nickname: "My Visa",
//                isEnabled: true,
//                renterID: 1001,
//                lastUsedDateTime: "2025-07-23T12:00:00Z"
//            ),
//            CreditCard(
//                id: 2,
//                cardholderName: "Leon Guo",
//                maskedCardNumber: "**** **** **** 4545",
//                network: "Visa",
//                expiration: "07/29",
//                token: "tok_sample",
//                md5: "abc123",
//                nickname: "My Visa",
//                isEnabled: true,
//                renterID: 1001,
//                lastUsedDateTime: "2025-07-23T12:00:00Z"
//            )
//        ]
//    }
//
//    func deleteCard(at offsets: IndexSet) {
//        cards.remove(atOffsets: offsets)
//        // TODO: Delete API
//    }
//}

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
                    let tokenOpt = extractToken(from: response)
                        if let newToken = tokenOpt {
                            self.token = newToken
                            print("Updated token from response header")
                        }
                    do {
                        let decoded = try VeygoJsonStandard.shared.decoder.decode([PublishPaymentMethod].self, from: data)
                        self.cards = decoded
                    } catch {
                        print(String(data: data, encoding: .utf8) ?? "Unreadable JSON")
                        alertMessage = "Failed to parse response"
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

        cards.remove(atOffsets: offsets)
        // TODO: DELETE API
    }
}

#Preview {
    CreditCardView()
        .environmentObject(UserSession())
}
