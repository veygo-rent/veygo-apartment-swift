//
//  LoginView.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/18/25.
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var goToNameView = false

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                // Logo
                Image("VeygoLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding(.bottom, -20)

                // Email 输入框
                TextInputField(placeholder: "Email", text: $email)

                // 间距调整
                Spacer().frame(height: 15)

                // Password 输入框
                TextInputField(placeholder: "Password", text: $password, isSecure: true)

                // 登录按钮
                PrimaryButtonLg(text: "Login") {
                    print("Log In Pressed")
                }

                // 忘记密码
                ShortTextLink(text: "Forgot Password?") {
                    print("Forgot Password Pressed")
                }

                Spacer()

                // 注册按钮
                SecondaryButtonLg(text: "Create New Account") {
                    print("Create Account Pressed")
                    goToNameView = true
                }
                .padding(.top, 10)
                .padding(.bottom, 10)

                // Terms
                LegalText()
            }
            .padding(.horizontal, 32)
            .background(Color("MainBG"))
            .navigationDestination(isPresented: $goToNameView) {
                NameView()
            }
        }
    }
}

#Preview {
    LoginView()
}
