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

    var body: some View {
        VStack {
            Spacer()

            // Logo
            Image("VeygoDraft")
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
            ForgotPasswordButton {
                print("Forgot Password Pressed")
            }

            Spacer()

            // 注册按钮
            SecondaryButtonLg(text: "Create New Account") {
                print("Create Account Pressed")
            }
            .padding(.top, 10)
            .padding(.bottom, 10)

            // Terms
            LegalText()
        }
        .padding()
        .background(Color.white)
        .ignoresSafeArea()
    }
}

#Preview {
    LoginView()
}
