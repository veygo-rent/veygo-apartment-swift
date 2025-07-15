//
//  RewardView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 6/30/25.
//

import SwiftUI

struct RewardView: View {
    var body: some View {
        VStack(spacing: 0) {
            BannerView(title: "Plans", showTitle: true, showBackButton: false)
                .ignoresSafeArea(.container, edges: .top)

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
            }
        }
        .background(Color("MainBG"))
    }
}

#Preview {
    RewardView()
}


