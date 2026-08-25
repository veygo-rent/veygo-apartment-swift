//
//  LoginView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/12/26.
//

import SwiftUI

enum SignupRoute: Hashable {
    case name
    case age(renterInfo: NewRenter)
    case phone(renterInfo: NewRenter)
    case email(renterInfo: NewRenter)
    case password(renterInfo: NewRenter)

    case membership
    case privacy
    case tou
}

struct LoginView: View {

    @Environment(Session.self) private var session

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    @State private var isLoggingIn: Bool = false

    private enum Field: Hashable {
        case email
        case password
    }

    @State private var email: String = ""
    @State private var password: String = ""

    @State private var path = NavigationPath()
    @State private var signup = NewRenter()

    @State private var goToResetView = false

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

                TextInputField(text: $email, placeholder: "Email")
                    .onChange(of: email) { _, newValue in
                        email = newValue.lowercased()
                    }
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.none)
                    .focused($focusedField, equals: .email)
                Spacer().frame(height: 15)
                TextInputField(text: $password, placeholder: "Password", isSecure: true)
                    .focused($focusedField, equals: .password)
                Spacer().frame(height: 20)
                PrimaryButton(text: "Sign In") {
                    if email.isEmpty {
                        focusedField = .email
                    } else if password.isEmpty {
                        focusedField = .password
                    } else {
                        focusedField = nil
                        Task { await login() }
                    }
                }
                .disabled(isLoggingIn)
                .alert(alertTitle, isPresented: $showAlert) {
                    Button("OK") { }
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

                TextWithLink(fullText: "By using this App, you agree to its Terms of Use.", highlightedTexts: [
                    ("Terms of Use", { path.append(SignupRoute.tou) })
                ])
                TextWithLink(fullText: "By signing in, you agree to Veygo’s Privacy Policy and Membership Agreement.", highlightedTexts: [
                    ("Membership Agreement", { path.append(SignupRoute.membership) }),
                    ("Privacy Policy", { path.append(SignupRoute.privacy) })
                ])
                Spacer().frame(height: 15)
            }
            .padding(.horizontal, 32)
            .background(Color.mainBG.ignoresSafeArea().onTapGesture {
                focusedField = nil
            })
            .navigationDestination(for: SignupRoute.self) { route in
                switch route {
                case .name:                     NameView(path: $path)
                case .age(let renterInfo):      AgeView(renterInfo: renterInfo, path: $path)
                case .phone(let renterInfo):    PhoneView(renterInfo: renterInfo, path: $path)
                case .email(let renterInfo):    EmailView(renterInfo: renterInfo, path: $path)
                case .password(let renterInfo): PasswordView(renterInfo: renterInfo, path: $path)
                case .membership:               TermsView(term: .membershipAgreement)
                case .privacy:                  TermsView(term: .privacyPolicy)
                case .tou:                      TermsView(term: .termsOfUse)
                }
            }
            .navigationDestination(isPresented: $goToResetView) {
                ResetView(currentEmail: email)
            }
        }
    }

    private func login() async {
        isLoggingIn = true
        defer { isLoggingIn = false }

        do {
            let body = ["email": email, "password": password]
            let jsonData = try VeygoJsonStandard.shared.encoder.encode(body)

            let request = veygoCurlRequest(url: "/api/v1/user/login", method: .post, body: jsonData)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                present(.E_DEFAULT)
                return
            }

            guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                present(.E_DEFAULT)
                return
            }

            switch httpResponse.statusCode {
            case 200:
                let token = extractToken(from: response, for: "Logging in") ?? ""
                guard let renter = try? VeygoJsonStandard.shared.decoder.decode(PublishRenter.self, from: data) else {
                    present(title: "Server Error", message: "Invalid content")
                    return
                }
                // Store credentials + profile. This flips the app into the
                // authenticated state; RootView / gating handles navigation.
                session.login(token: token, userId: renter.id, renter: renter)

            case 401:
                let err = (try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)) ?? .E401
                session.clear()
                present(err)

            case 405:
                let err = (try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)) ?? .E405
                present(err)

            default:
                present(title: ErrorResponse.E_DEFAULT.title,
                        message: "\(ErrorResponse.E_DEFAULT.message) (\(httpResponse.statusCode))")
            }
        } catch let error as URLError {
            switch error.code {
            case .timedOut:            present(.E_TIME_OUT)
            case .notConnectedToInternet: present(.E_NO_INTERNET)
            default:                   present(.E_DEFAULT)
            }
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func present(_ error: ErrorResponse) {
        present(title: error.title, message: error.message)
    }

    private func present(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
