//
//  ContactInfoPanel.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/4/25.
//
import SwiftUI

struct ContactInfoPanel: View {
    var phone: String
    var email: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Customer Support")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color("FootNote"))

            HStack(alignment: .top, spacing: 12) {
                Image("Phone")
                    .resizable()
                    .frame(width: 35, height: 35)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Phone Number")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color("FootNote"))

                    Link(phone, destination: URL(string: "tel:\(phone)")!)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color("TextBlackPrimary"))
                }
            }

            HStack(alignment: .top, spacing: 12) {
                Image("Email")
                    .resizable()
                    .frame(width: 35, height: 35)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Email")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color("FootNote"))

                    Link(email, destination: URL(string: "mailto:\(email)")!)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color("TextBlackPrimary"))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .frame(width: 317, height: 173)
        .background(Color("CardBG"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.17), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 4, y: 4)
    }
}

#Preview {
    ContactInfoPanel(phone: "+1 (765) 273-3727", email: "info@veygo.rent")
}

