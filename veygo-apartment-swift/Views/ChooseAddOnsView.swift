//
//  ChooseAddOnsView.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/10/25.
//

import SwiftUI
struct ChooseAddOnsView: View {
    @State private var insuranceSelected = false
    @State private var cdwSelected = false
    @State private var additionalDriverCount = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        BackButton()
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.leading, 20)

                    Text("Choose Your Add-ons")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(Color("TextBlackPrimary"))
                        .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Protection and Coverages")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color("TextBlackPrimary"))
                            .padding(.horizontal, 20)

                        Divider()
                            .padding(.horizontal, 20)
                            .background(Color("SeparateLine"))

                        AddOnCardBool(
                            title: .constant("Liability Insurance"),
                            description: .constant("Indiana-minimum protection for others’ injuries/property; excludes rental car."),
                            pricePerDay: .constant("$19.98/day"),
                            isSelected: $insuranceSelected
                        )
                        .padding(.horizontal, 20)

                        AddOnCardBool(
                            title: .constant("Collision Damage Waiver (CDW)"),
                            description: .constant("Covers rental car damage/theft; you pay up to $1,000 deductible."),
                            pricePerDay: .constant("$28.99/day"),
                            isSelected: $cdwSelected
                        )
                        .padding(.horizontal, 20)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Additional Drivers")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color("TextBlackPrimary"))
                            .padding(.horizontal, 20)

                        Divider()
                            .padding(.horizontal, 20)
                            .background(Color("SeparateLine"))

                        AddOnCardNum(
                            title: .constant("Additional Driver"),
                            description: .constant("Add a friend (eligible license / age) to share driving. Same coverage applies."),
                            pricePerDay: .constant("$19.98/day"),
                            count: $additionalDriverCount
                        )
                        .padding(.horizontal, 20)
                    }

                    Spacer().frame(height: 120)
                }
            }

            HStack {
                Spacer()
                PrimaryButtonLg(text: "Continue", action: {
                    // TODO: Continue action
                })
                .frame(width: 221)
                Spacer()
            }
            .padding(.bottom, 20)
            .background(Color.white.ignoresSafeArea(edges: .bottom))
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ChooseAddOnsView()
}
