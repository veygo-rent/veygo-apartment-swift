//
//  CreditCardView.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/24/25.
//

import SwiftUI

struct CreditCardView: View {
    @State private var cards: [CreditCard] = []
    @State private var expandedCardID: Int? = nil
    @State private var navigateToAddCard = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
//                Text("Your Cards")
//                    .font(.title2)
//                    .bold()
//                    .padding(.horizontal)

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
        }
    }

    func loadCards() {
        // TODO: GET API
        self.cards = [
            CreditCard(
                id: 1,
                cardholderName: "Xinyi Guan",
                maskedCardNumber: "**** **** **** 4242",
                network: "Visa",
                expiration: "12/26",
                token: "tok_sample",
                md5: "abc123",
                nickname: "My Visa",
                isEnabled: true,
                renterID: 1001,
                lastUsedDateTime: "2025-07-23T12:00:00Z"
            ),
            CreditCard(
                id: 2,
                cardholderName: "Leon Guo",
                maskedCardNumber: "**** **** **** 4545",
                network: "Visa",
                expiration: "07/29",
                token: "tok_sample",
                md5: "abc123",
                nickname: "My Visa",
                isEnabled: true,
                renterID: 1001,
                lastUsedDateTime: "2025-07-23T12:00:00Z"
            )
        ]
    }

    func deleteCard(at offsets: IndexSet) {
        cards.remove(atOffsets: offsets)
        // TODO: Delete API
    }
}

#Preview {
    CreditCardView()
}
