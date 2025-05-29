//
//  EmailView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//
import SwiftUI

struct EmailView: View {
    @State private var email: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var goToPasswordView = false

    @State private var descriptions: [(String, Bool)] = [
        ("Your email has to be in the correct format", false),
        ("Your email will also be used for communication of important account updates.", false)
    ]
    @EnvironmentObject var signup: SignupSession

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                // 返回按钮
                Button(action: {
                    dismiss()
                }) {
                    BackButton()
                }
                .padding(.top, 90)
                .padding(.leading, 30)

                VStack(alignment: .leading, spacing: 20) {
                    Spacer()

                    // 标题
                    LargeTitleText(text: "Send Letters\nThe Old Way")
                        .padding(.bottom, 90)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // 输入框与说明
                    VStack(alignment: .leading, spacing: 5) {
                        InputWithLabel(
                            label: "Your Email Address",
                            placeholder: "info@Veygo.rent",
                            text: $email,
                            descriptions: $descriptions
                        )
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    // 下一步按钮
                    ArrowButton(isDisabled: !EmailValidator(email: email).isValidEmail) {
                        signup.student_email = email //??
                        goToPasswordView = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 50)
                }
                .onChange(of: email) { oldValue, newValue in
                    descriptions[0].1 = !EmailValidator(email: newValue).isValidEmail
                    descriptions[1].1 = false // 始终灰色
                }
                .padding(.top, 40)
            }
            .background(Color("MainBG"))
            .ignoresSafeArea()
            .navigationDestination(isPresented: $goToPasswordView) {
                PasswordView()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    EmailView()
}


