//
//  PlanCard.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/14/25.
//

import SwiftUI

struct PlanCard: View {
    var title: String
    var subtitle: String
    var price: String
    var billingCycle: String
    var features: [String]
    var isCurrentPlan: Bool
    var isFreePlan: Bool = false
    var onSwitch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundColor(Color("TextPinkPrimary"))

                Spacer()

                if isCurrentPlan {
                    LargerPrimaryButtonLg(text: "Current", action: {})
                        .frame(width: 102, height: 36)
                        .padding(.top, 4)
                        .disabled(true)
                } else {
                    LargerPrimaryButtonLg(text: "Switch Plan", action: onSwitch)
                        .frame(width: 130, height: 36)
                        .padding(.top, 4)
                }
            }

            Text(subtitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color("TextPinkPrimary").opacity(0.7))
                .underline()

            if isFreePlan {
                Text(price)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color("TextPinkPrimary"))
            } else {
                Text("\(price) / \(billingCycle)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color("TextPinkPrimary"))

            }

            ForEach(features, id: \.self) { feature in
                HStack(alignment: .top, spacing: 2) {
                    Text("•")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("TextPinkPrimary"))
                    Text(feature)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("TextPinkPrimary"))
                }
            }
        }
        .padding()
        .background(Color("TextBluePrimary"))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
        .frame(width: 338)
    }

}

#Preview {
    VStack(spacing: 24) {
        PlanCard(
            title: "Basic",
            subtitle: "Standard tier with base rewards.",
            price: "Free",
            billingCycle: "", // ✅ 不显示
            features: [
                "Access to rent cars"
            ],
            isCurrentPlan: true,
            isFreePlan: true, // ✅ 标记为 Free
            onSwitch: { print("Switch to Basic") }
        )

        PlanCard(
            title: "Plus",
            subtitle: "Standard tier with base rewards.",
            price: "$10.99",
            billingCycle: "month",
            features: [
                "Access to rent cars",
                "Free additional driver for rentals"
            ],
            isCurrentPlan: false,
            onSwitch: { print("Switch to Plus") }
        )

        PlanCard(
            title: "Premier",
            subtitle: "The most premium tier with highest rewards.",
            price: "$24.99",
            billingCycle: "month",
            features: [
                "Access to rent cars",
                "Free additional driver for rentals",
                "Free upgrade to premium cars",
                "10% discount on ALL rentals"
            ],
            isCurrentPlan: false,
            onSwitch: { print("Switch to Premier") }
        )
    }
}
