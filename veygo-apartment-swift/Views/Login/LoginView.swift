//
//  LoginView.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/18/25.
//

import SwiftUI

let BASE_PATH = "https://dev.veygo.rent"

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var goToNameView = false
    @State private var goToHomeView = false
    @State private var goToResetView = false

    @State private var showAlert = false
    @State private var alertMessage = ""

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

                Spacer().frame(height: 15)

                // Password 输入框
                TextInputField(placeholder: "Password", text: $password, isSecure: true)

                // 登录按钮
                PrimaryButtonLg(text: "Login") {
                    if email.isEmpty {
                        alertMessage = "Please enter your email"
                        showAlert = true
                    } else if password.isEmpty {
                        alertMessage = "Please enter your password"
                        showAlert = true
                    } else {
                        loginUser()
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Login Failed"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }

                // 忘记密码
                ShortTextLink(text: "Forgot Password?") {
                    goToResetView = true
                }

                Spacer()

                // 注册按钮
                SecondaryButtonLg(text: "Create New Account") {
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
            .navigationDestination(isPresented: $goToHomeView) {
                HomeView()
            }
            .navigationDestination(isPresented: $goToResetView) {
                ResetView()
            }
        }
    }

    func loginUser() {
        guard let url = URL(string: "\(BASE_PATH)/api/v1/user/login") else {
            print("Invalid URL")
            return
        }

        let body: [String: String] = [
            "email": email,
            "password": password
        ]

        let jsonData = try? JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showAlert = true
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  let data = data else {
                DispatchQueue.main.async {
                    alertMessage = "Invalid server response."
                    showAlert = true
                }
                return
            }

            if httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    goToHomeView = true
                }
            } else if httpResponse.statusCode == 401 {
                let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                _ = responseJSON?["error"] as? String ?? "Credentials invalid"

                DispatchQueue.main.async {
                    alertMessage = "Email or password is incorrect"
                    showAlert = true
                }
            } else {
                DispatchQueue.main.async {
                    alertMessage = "Unexpected error (code: \(httpResponse.statusCode))."
                    showAlert = true
                }
            }
        }.resume()
    }
}

#Preview {
    LoginView()
}
