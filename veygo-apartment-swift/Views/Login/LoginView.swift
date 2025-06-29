//
//  LoginView.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/18/25.
//

import SwiftUI

enum SignupRoute: Hashable {
    case name
    case age
    case phone
    case email
    case password
}

struct LoginView: View {
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var path = NavigationPath()
    @StateObject private var signup = SignupSession()
    
    @State private var goToResetView = false

    @State private var showAlert = false
    @State private var alertMessage = ""

    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0
    
    @EnvironmentObject var session: UserSession
    
    @FocusState private var focusedField: String?
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Spacer()

                Image("VeygoLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)

                TextInputField(placeholder: "Email", text: $email)
                    .onChange(of: email) { oldValue, newValue in
                        email = newValue.lowercased()
                    }
                    .focused($focusedField, equals: "email")
                    .onSubmit {
                        focusedField = "password"
                    }
                Spacer().frame(height: 15)
                TextInputField(placeholder: "Password", text: $password, isSecure: true)
                    .focused($focusedField, equals: "password")
                    .onSubmit {
                        if email.isEmpty {
                            focusedField = "email"
                        } else if password.isEmpty {
                            focusedField = "password"
                        } else {
                            loginUser()
                        }
                    }
                Spacer().frame(height: 20)
                PrimaryButtonLg(text: "Login") {
                    if email.isEmpty {
                        focusedField = "email"
                    } else if password.isEmpty {
                        focusedField = "password"
                    } else {
                        loginUser()
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Login Failed"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }

                Spacer().frame(height: 20)
                ShortTextLink(text: "Forgot Password?") {
                    goToResetView = true
                }.padding(.leading, 10)

                Spacer()

                SecondaryButtonLg(text: "Create New Account") {
                    path.append(SignupRoute.name)
                }
                .padding(.top, 50)
                .padding(.bottom, 10)

                LegalText()
                Spacer().frame(height: 15)
            }
            .padding(.horizontal, 32)
            .background(Color("MainBG").ignoresSafeArea())
            .navigationDestination(for: SignupRoute.self) { route in
                switch route {
                case .name:
                    NameView(signup: signup, path: $path)
                case .age:
                    AgeView(signup: signup, path: $path)
                case .phone:
                    PhoneView(signup: signup, path: $path)
                case .email:
                    EmailView(signup: signup, path: $path)
                case .password:
                    PasswordView(signup: signup, path: $path)
                }
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
                   let decodedUser = try? VeygoDecoderStandard.shared.decoder.decode(PublishRenter.self, from: renterJSON) {
                    // Update AppStorage
                    self.token = extractToken(from: response)!
                    self.userId = decodedUser.id
                    DispatchQueue.main.async {
                        // Update UserSession
                        self.session.user = decodedUser
                    }
                    print("\nLogin successful: \(self.token) \(decodedUser.id)\n")
                    DispatchQueue.main.async {
                        self.session.user = decodedUser
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
}

#Preview {
    LoginView()
}
