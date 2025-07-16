//
//  Plans.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/14/25.
//
//
//  Plans.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/14/25.
//

import SwiftUI

struct Plans: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PlanCard(
                    title: "Basic",
                    subtitle: "Start saving, no strings attached.",
                    price: "Free",
                    billingCycle: "",
                    features: [
                        "Access to rent cars",
                        "Free additional driver for rentals",
                        "Free upgrade to premium cars",
                        "10% discount on ALL rentals"
                    ],
                    isCurrentPlan: true,
                    isFreePlan: true,
                    onSwitch: {}
                )

                PlanCard(
                    title: "Plus",
                    subtitle: "More savings, lower fees.",
                    price: "$10.99",
                    billingCycle: "month",
                    features: [
                        "Access to rent cars",
                        "Free additional driver for rentals",
                        "Free upgrade to premium cars",
                        "10% discount on ALL rentals"
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
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .navigationTitle("Plans")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color("Accent2Color").opacity(0.6), for: .navigationBar)
        .background(Color("MainBG"))
    }
}

#Preview {
    NavigationStack {
        Plans()
    }
}
