import SwiftUI

struct PasswordView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @EnvironmentObject var session: UserSession
    @State private var password: String = ""
    @State private var goToCongratsView = false
    
    @State private var descriptions: [(String, Bool)] = [
        ("Password must be at least:", false),
        ("· at least 8 digits long", false),
        ("· at least one number and one special character\n  eg. (!@#$%^&*_+=?/~';,<>\u{7C})", false)
    ]
    
    @Binding var signup: SignupSession
    @Binding var path: NavigationPath
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if #unavailable(iOS 26) {
                Button(action: {
                    path.removeLast()
                }) {
                    BackButton()
                }
                .padding(.top, 90)
                .padding(.leading, 30)
            }
            
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                
                LargeTitleText(text: "Keep Your\nAccount Safe")
                    .padding(.bottom, 90)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                VStack(alignment: .leading, spacing: 5) {
                    InputWithLabel(
                        label: "Your Account Password",
                        placeholder: "veygo2022!",
                        isSecure: true,
                        text: $password,
                        descriptions: $descriptions
                    )
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                ArrowButton(isDisabled: !isPasswordValid(password)) {
                    signup.password = password
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await registerUserAsync(token, userId)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 30)
                
                LegalText(
                    fullText: "By joining, you agree to Veygo’s Terms and Conditions",
                    highlightedText: "Terms and Conditions"
                )
                .padding(.horizontal, 32)
                .offset(y: -25)
            }
            .onChange(of: password) { _, newValue in
                descriptions[0].1 = false
                descriptions[1].1 = newValue.count < 8
                descriptions[2].1 = !(containsNumber(newValue) && containsSpecialChar(newValue))
            }
            .padding(.top, 40)
        }
        .background(Color("MainBG"))
        .ignoresSafeArea()
        .navigationDestination(isPresented: $goToCongratsView) {
            CongratsView(user: $session.user)
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
        .modifier(BackButtonHiddenModifier())
        .swipeBackGesture {
            path.removeLast()
        }
    }
    
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
    
    @ApiCallActor func registerUserAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        guard let dobUsFormat: String = await signup.date_of_birth,
              let dobDate: Date = VeygoDatetimeStandard.shared.usStandardDateFormatter.date(from: dobUsFormat) else {
            return .doNothing
        }
        do {
            let dob: String = VeygoDatetimeStandard.shared.yyyyMMddDateFormatter.string(from: dobDate)
            let body = await [
                "name": signup.name!,
                "student_email": signup.student_email!,
                "password": signup.password!,
                "phone": signup.phone!,
                "date_of_birth": dob
            ]
            let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(body)
            let request = veygoCurlRequest(url: "/api/v1/user/create", method: .post, body: jsonData)
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
            
            nonisolated struct ErrorMsg: Decodable {
                let error: String
            }
            
            switch httpResponse.statusCode {
            case 201:
                nonisolated struct LoginSuccessBody: Decodable {
                    let renter: PublishRenter
                }
                
                let token = extractToken(from: response) ?? ""
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(LoginSuccessBody.self, from: data),
                      !token.isEmpty else {
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
            case 400:
                // BAD_REQUEST
                let errMsg: String
                if let decodedErrMsg = try? VeygoJsonStandard.shared.decoder.decode(ErrorMsg.self, from: data).error {
                    errMsg = decodedErrMsg
                } else {
                    errMsg = "Bad register request"
                }
                await MainActor.run {
                    alertTitle = "Register failed"
                    alertMessage = errMsg
                    showAlert = true
                }
                return .doNothing
            case 405:
                await MainActor.run {
                    alertTitle = "Internal Error"
                    alertMessage = "Method not allowed, please contact the developer dev@veygo.rent"
                    showAlert = true
                }
                return .doNothing
            case 406:
                // BAD_REQUEST
                let errMsg: String
                if let decodedErrMsg = try? VeygoJsonStandard.shared.decoder.decode(ErrorMsg.self, from: data).error {
                    errMsg = decodedErrMsg
                } else {
                    errMsg = "Unexpeted error while registering"
                }
                await MainActor.run {
                    alertTitle = "Register failed"
                    alertMessage = errMsg
                    showAlert = true
                }
                return .doNothing
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
