//
//  PhoneVeri.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/16/25

import SwiftUI

struct PhoneVeri: View {
    @State private var phoneNumber: String = "312-810-3169" // 模拟后端拉取
    @State private var verificationCode: String = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)
            HStack(spacing: 12) {
                InputWithInlinePrompt(promptText: "Your Phone number", userInput: $phoneNumber)
                    .disabled(true)
                    .foregroundColor(Color("FootNote"))

                SecondaryButtonLg(text: "Send Code") {
                    print("Send code to \(phoneNumber)")
                }
                .frame(width: 120)
            }

            InputWithInlinePrompt(promptText: "Verification code", userInput: $verificationCode)

            HStack {
                PrimaryButtonLg(text: "Verify") {
                    print("Verifying code \(verificationCode)")
                }
                .frame(maxWidth: .infinity)
            }

            HStack {
                Spacer()
                ShortTextLink(text: "Change Phone Number") {
                    print("User wants to change phone number")
                }
                Spacer()
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .navigationTitle("Verify Your Phone Number")
        //.navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color("Accent2Color").opacity(0.6), for: .navigationBar)
    }
}

#Preview {
    PhoneVeri()
}
