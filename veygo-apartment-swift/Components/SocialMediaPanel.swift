//
//  SocialMediaPanel.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/4/25.
//

import SwiftUI

struct SocialMediaPanel: View {
    var Instagram: String
    var X: String
    var Facebook: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Social Media")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color("FootNote"))

            HStack(alignment: .top, spacing: 12) {
                Image("Instagram")
                    .resizable()
                    .frame(width: 35, height: 35)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Instagram")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color("FootNote"))

                    Text("@rentveygo")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color("TextBlackPrimary"))
                }
            }

            HStack(alignment: .top, spacing: 12) {
                Image("X")
                    .resizable()
                    .frame(width: 35, height: 35)

                VStack(alignment: .leading, spacing: 4) {
                    Text("X")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color("FootNote"))

                    Text("@rentveygo")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color("TextBlackPrimary"))
                }
            }
            HStack(alignment: .top, spacing: 12) {
                Image("Facebook")
                    .resizable()
                    .frame(width: 35, height: 35)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Facebook")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color("FootNote"))

                    Text("@rentveygo")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color("TextBlackPrimary"))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .frame(width: 317, height: 234)
        .background(Color("MainBG"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.17), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 4, y: 4)
    }
}

#Preview {
    SocialMediaPanel(Instagram:"info@veygo.rent", X: "info@veygo.rent", Facebook: "info@veygo.rent")
}

