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
//                Image(systemName: card.network == "Visa" ? "creditcard.fill" : "creditcard")
//                    .resizable()
//                    .frame(width: 32, height: 22)
//                    .foregroundColor(.primaryButtonBg)
                cardBrandImage(for: card.network)
                    .frame(width: 32, height: 32)
                    .cornerRadius(4)

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
                    Text("Nickname: \(card.nickname ?? "None")")
                    Text("Enabled: \(card.isEnabled ? "Yes" : "No")")
                    Text("Last Used: \(card.lastUsedDateTime)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .transition(.opacity.combined(with: .slide))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .animation(.easeInOut, value: isExpanded)
    }
}

@ViewBuilder
func cardBrandImage(for brand: String) -> some View {
    let lowercased = brand.lowercased()
    let knownBrands = ["visa", "master", "amex", "discover", "union", "jcb", "dinner"]

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


