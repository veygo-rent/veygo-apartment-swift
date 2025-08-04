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
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false

    private enum Field: Hashable {
        case email
        case password
    }
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var path = NavigationPath()
    @State private var signup = SignupSession()
    
    @State private var goToResetView = false

    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0
    
    @EnvironmentObject var session: UserSession
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Spacer()

                Image("VeygoLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .onTapGesture {
                        focusedField = nil
                    }

                TextInputField(placeholder: "Email", text: $email)
                    .onChange(of: email) { oldValue, newValue in
                        email = newValue.lowercased()
                    }
                    .focused($focusedField, equals: .email)
                Spacer().frame(height: 15)
                TextInputField(placeholder: "Password", text: $password, isSecure: true)
                    .focused($focusedField, equals: .password)
                Spacer().frame(height: 20)
                PrimaryButton(text: "Login") {
                    if email.isEmpty {
                        focusedField = .email
                    } else if password.isEmpty {
                        focusedField = .password
                    } else {
                        Task {
                            await ApiCallActor.shared.appendApi { token, userId in
                                await loginUserAsync()
                            }
                        }
                    }
                }
                .alert(alertTitle, isPresented: $showAlert) {
                    Button("OK") {
                        if clearUserTriggered {
                            session.user = nil
                        }
                    }
                } message: {
                    Text(alertMessage)
                }

                Spacer().frame(height: 20)
                ShortTextLink(text: "Forgot Password?") {
                    goToResetView = true
                }.padding(.leading, 10)

                Spacer()

                SecondaryButton(text: "Create New Account") {
                    path.append(SignupRoute.name)
                }
                .padding(.top, 50)
                .padding(.bottom, 10)

                LegalText()
                Spacer().frame(height: 15)
            }
            .padding(.horizontal, 32)
            .background(Color("MainBG").ignoresSafeArea().onTapGesture {
                focusedField = nil
            })
            .navigationDestination(for: SignupRoute.self) { route in
                switch route {
                case .name:
                    NameView(signup: $signup, path: $path)
                case .age:
                    AgeView(signup: $signup, path: $path)
                case .phone:
                    PhoneView(signup: $signup, path: $path)
                case .email:
                    EmailView(signup: $signup, path: $path)
                case .password:
                    PasswordView(signup: $signup, path: $path)
                }
            }
            .navigationDestination(isPresented: $goToResetView) {
                ResetView()
            }
        }
    }
    
    @ApiCallActor func loginUserAsync() async -> ApiTaskResponse {
        do {
            let body = await ["email": email, "password": password]
            let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(body)
            
            let request = veygoCurlRequest(url: "/api/v1/user/login", method: "POST", body: jsonData)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    alertTitle = "Server Error"
                    alertMessage = "Invalid protocol"
                    showAlert = true
                }
                return .doNothing
            }
            
            guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                await MainActor.run {
                    alertTitle = "Server Error"
                    alertMessage = "Invalid content"
                    showAlert = true
                }
                return .doNothing
            }
            
            switch httpResponse.statusCode {
            case 200:
                nonisolated struct LoginSuccessBody: Decodable {
                    let renter: PublishRenter
                }
                
                let token = extractToken(from: response) ?? ""
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(LoginSuccessBody.self, from: data) else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                await MainActor.run {
                    self.session.user = decodedBody.renter
                }
                return .loginSuccessful(userId: decodedBody.renter.id, token: token)
            case 401:
                await MainActor.run {
                    alertTitle = "Login Failed"
                    alertMessage = "Wrong email or password"
                    showAlert = true
                    clearUserTriggered = true
                }
                return .clearUser
            case 405:
                await MainActor.run {
                    alertTitle = "Internal Error"
                    alertMessage = "Method not allowed, please contact the developer dev@veygo.rent"
                    showAlert = true
                    clearUserTriggered = true
                }
                return .clearUser
            default:
                await MainActor.run {
                    alertTitle = "Application Error"
                    alertMessage = "Unrecognized response, make sure you are running the latest version"
                    showAlert = true
                }
                return .doNothing
            }
        } catch {
            await MainActor.run {
                alertTitle = "Internal Error"
                alertMessage = "\(error.localizedDescription)"
                showAlert = true
            }
            return .doNothing
        }
    }
}

#Preview {
    LoginView()
}
