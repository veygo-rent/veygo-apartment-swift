//
//  PasswordView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//
import SwiftUI

struct PasswordView: View {
    @State private var password: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var goToHubView = false

    @State private var descriptions: [(String, Bool)] = [
        ("Password must be at least:", false),
        ("· at least 8 digits long", false),
        ("· at least one number and one special character\n  eg. (!@#$%^&*_+=?/~';,<>\u{7C})", false)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                // Back button
                Button(action: {
                    dismiss()
                }) {
                    BackButton()
                }
                .padding(.top, 90)
                .padding(.leading, 30)

                VStack(alignment: .leading, spacing: 20) {
                    Spacer()

                    // Title
                    LargeTitleText(text: "Keep Your\nAccount Safe")
                        .padding(.bottom, 90)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // Input field
                    VStack(alignment: .leading, spacing: 5) {
                        InputWithLabel(
                            label: "Your Account Password",
                            placeholder: "iloveveygo",
                            text: $password,
                            descriptions: $descriptions
                        )
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    // Arrow Button
                    ArrowButton(isDisabled: !isPasswordValid(password)) {
                        goToHubView = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 30)

                    // Terms text (draft just for now)
                    LegalText(
                        fullText: "By joining, you agree to Veygo’s Terms and Conditions",
                        highlightedText: "Terms and Conditions"
                    )
                    .padding(.horizontal, 32)
                    .offset(y: -25)
                }
                .onChange(of: password) { _, newValue in
                    descriptions[0].1 = false // 永远灰色
                    descriptions[1].1 = newValue.count < 8
                    descriptions[2].1 = !(containsNumber(newValue) && containsSpecialChar(newValue))
                }
                .padding(.top, 40)
            }
            .background(Color("MainBG"))
            .ignoresSafeArea()
            .navigationDestination(isPresented: $goToHubView) {
                HubView()
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Validation Helpers
    private func containsNumber(_ text: String) -> Bool {
        let numberRegex = ".*[0-9].*"
        return NSPredicate(format: "SELF MATCHES %@", numberRegex).evaluate(with: text)
    }

    private func containsSpecialChar(_ text: String) -> Bool {
        let specialCharacterRegex = ".*[!@#$%^&*()_+=?/~';,<>\\|].*"
        return NSPredicate(format: "SELF MATCHES %@", specialCharacterRegex).evaluate(with: text)
    }

    private func isPasswordValid(_ password: String) -> Bool {
        return password.count >= 8 && containsNumber(password) && containsSpecialChar(password)
    }
}

#Preview {
    PasswordView()
}
