//
//  Banner.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/4/25.
//

import SwiftUI

struct BannerView: View {
    var title: String = "Contact Us"
    var showTitle: Bool = true
    var showBackButton: Bool = true
    var onBack: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color("Accent2Color").opacity(0.6))
                .frame(height: 100)
                .frame(maxWidth: .infinity)

            HStack {
                if showBackButton {
                    Button(action: {
                            onBack?()
                    }) {
                            BackButton()
                    }
                    .padding(.leading, 24)
                } else {
                    Spacer()
                        .frame(width: 44)
                }

                Spacer()

                if showTitle {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color("TextBlackPrimary"))
                }

                Spacer()
                Spacer()
                    .frame(width: 44)
            }
            .padding(.top, 40)
        }
    }
}


#Preview {
    BannerView()
}
