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
                    .autocorrectionDisabled(true)
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

                TextWithLink(fullText: "By signing in, you agree to Veygo’s Membership Agreement and our Privacy Policy", highlightedTexts: [
                    ("Membership Agreement", "https://dev.veygo.rent/membership"),
                    ("Privacy Policy", "https://dev.veygo.rent/privacy")
                ])
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
                ResetView(currentEmail: email)
            }
        }
    }
    
    @ApiCallActor func loginUserAsync() async -> ApiTaskResponse {
        do {
            let body = await ["email": email, "password": password]
            let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(body)
            
            let request = veygoCurlRequest(url: "/api/v1/user/login", method: .post, body: jsonData)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let body = ErrorResponse.WRONG_PROTOCOL
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
                return .doNothing
            }
            
            guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                let body = ErrorResponse.E_DEFAULT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
                return .doNothing
            }
            
            switch httpResponse.statusCode {
            case 200:
                let token = extractToken(from: response, for: "Logging in") ?? ""
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(PublishRenter.self, from: data) else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                await MainActor.run {
                    self.session.user = decodedBody
                }
                return .loginSuccessful(userId: decodedBody.id, token: token)
            case 401:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                        clearUserTriggered = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E401
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                        clearUserTriggered = true
                    }
                }
                return .clearUser
            case 405:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E405
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                }
                return .doNothing
            default:
                let body = ErrorResponse.E_DEFAULT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = "\(body.message) (\(httpResponse.statusCode))"
                    showAlert = true
                }
                return .doNothing
            }
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                let body = ErrorResponse.E_TIME_OUT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
            case .notConnectedToInternet:
                let body = ErrorResponse.E_NO_INTERNET
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
            default:
                let body = ErrorResponse.E_DEFAULT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
            }
            return .doNothing
        } catch {
            let body = ErrorResponse.E_DEFAULT
            await MainActor.run {
                alertTitle = body.title
                alertMessage = body.message
                showAlert = true
            }
            return .doNothing
        }
    }
}
