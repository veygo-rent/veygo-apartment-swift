//
//  CreditCardRow.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/24/25.
//

import SwiftUI

struct CreditCardRow: View {
    let card: PublishPaymentMethod
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 16) {
                Image(systemName: card.network == "Visa" ? "creditcard.fill" : "creditcard")
                    .resizable()
                    .frame(width: 32, height: 22)
                    .foregroundColor(.primaryButtonBg)

                VStack(alignment: .leading, spacing: 4) {
                    Text(card.maskedCardNumber)
                        .font(.headline)
                    Text("Exp: \(card.expiration)")
                        .font(.subheadline)
                        .foregroundColor(.footNote)
                }

                Spacer()

                Text(card.cardholderName)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .onTapGesture {
                onTap()
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                    if let nick = card.nickname {
                        Text("Nickname: \(nick)")
                    }
//                    Text("Enabled: \(card.is_enabled ? "Yes" : "No")")
                    if let date = card.lastUsedDateTime {
                        Text("Last Used: \(date)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CreditCardRow_Previews: PreviewProvider {
    static var previews: some View {
        CreditCardRow(
            card: PublishPaymentMethod(
                id: 1,
                cardholderName: "Xinyi Guan",
                maskedCardNumber: "**** **** **** 4242",
                network: "Visa",
                expiration: "12/26",
                //token: "tok_sample",
                md5: "abc123",
                nickname: "My Visa",
                isEnabled: true,
                renterID: 1001,
                lastUsedDateTime: "2025-07-23T12:00:00Z"
            ),
            isExpanded: true,
            onTap: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
