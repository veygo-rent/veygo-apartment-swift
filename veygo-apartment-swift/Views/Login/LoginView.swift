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
    @State private var goToHomeView = false
    @State private var goToResetView = false
    

    @State private var showAlert = false
    @State private var alertMessage = ""

    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0
    @EnvironmentObject var session: UserSession // this page can check envObj

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                Image("VeygoLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding(.bottom, -20)

                TextInputField(placeholder: "Email", text: $email)
                    .onChange(of: email) { oldValue, newValue in
                        email = newValue.lowercased()
                    }
                Spacer().frame(height: 15)
                TextInputField(placeholder: "Password", text: $password, isSecure: true)

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
                    Alert(title: Text("Login Failed"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }

                ShortTextLink(text: "Forgot Password?") {
                    goToResetView = true
                }

                Spacer()

                SecondaryButtonLg(text: "Create New Account") {
                    goToNameView = true
                }
                .padding(.top, 10)
                .padding(.bottom, 10)

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
        let body: [String: String] = ["email": email, "password": password]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        
        let request = veygoCurlRequest(url: "/api/v1/user/login", method: "POST", body: jsonData)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showAlert = true
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                DispatchQueue.main.async {
                    alertMessage = "Invalid server response."
                    showAlert = true
                }
                return
            }

            if httpResponse.statusCode == 200 {
                let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let renterData = responseJSON?["renter"],
                   let renterJSON = try? JSONSerialization.data(withJSONObject: renterData),
                   let decodedUser = try? JSONDecoder().decode(PublishRenter.self, from: renterJSON) {
                    // Update AppStorage
                    self.token = extractToken(from: response)!
                    self.userId = decodedUser.id
                    DispatchQueue.main.async {
                        // Update UserSession
                        self.session.user = decodedUser
                    }
                    print("\nLogin successful: \(self.token) \(decodedUser.id)\n")
                    DispatchQueue.main.async {
                        self.goToHomeView = true
                    }
                }
            } else if httpResponse.statusCode == 401 {
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

    func extractToken(from response: URLResponse?) -> String? {
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Failed to cast response to HTTPURLResponse")
            return nil
        }
        let token = httpResponse.value(forHTTPHeaderField: "token")
        print("Extracted token from header: \(token ?? "nil")")
        return token
    }
}

#Preview {
    LoginView()
}
