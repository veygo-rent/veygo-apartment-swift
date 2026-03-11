import SwiftUI

struct PasswordView: View {
    @FocusState private var fieldIsFocused: Bool
    
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
            
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                
                LargeTitleText(text: "Last Step\nYour Password")
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
                    .focused($fieldIsFocused)
                    .sensoryFeedback(.selection, trigger: fieldIsFocused)
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
                
                TextWithLink(fullText: "By joining, you agree to Veygo’s Membership Agreement and Privacy Policy.", highlightedTexts: [
                    ("Membership Agreement", { path.append(SignupRoute.membership) }),
                    ("Privacy Policy", { path.append(SignupRoute.privacy) })
                ])
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
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
        .onTapGesture {
            fieldIsFocused = false
        }
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
            case 201:
                let token = extractToken(from: response, for: "Registering user") ?? ""
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(PublishRenter.self, from: data),
                      !token.isEmpty else {
                    let body = ErrorResponse.E_DEFAULT
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                    return .doNothing
                }
                await MainActor.run {
                    self.session.user = decodedBody
                }
                return .loginSuccessful(userId: decodedBody.id, token: token)
            case 400:
                // BAD_REQUEST
                if let decodedErrMsg = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedErrMsg.title
                        alertMessage = decodedErrMsg.message
                        showAlert = true
                    }
                } else {
                    let body = ErrorResponse.E400
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                }
                return .doNothing
            case 403:
                if let decodedErrMsg = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedErrMsg.title
                        alertMessage = decodedErrMsg.message
                        showAlert = true
                    }
                } else {
                    let body = ErrorResponse.E403
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                }
                return .doNothing
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
            case 406:
                if let decodedErrMsg = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedErrMsg.title
                        alertMessage = decodedErrMsg.message
                        showAlert = true
                    }
                } else {
                    let body = ErrorResponse.E406
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                }
                return .doNothing
            case 409:
                if let decodedErrMsg = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedErrMsg.title
                        alertMessage = decodedErrMsg.message
                        showAlert = true
                    }
                } else {
                    let body = ErrorResponse.E409
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                }
                return .doNothing
            case 500:
                if let decodedErrMsg = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedErrMsg.title
                        alertMessage = decodedErrMsg.message
                        showAlert = true
                    }
                } else {
                    let body = ErrorResponse.E500
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                }
                return .doNothing
            default:
                let body = ErrorResponse.E_DEFAULT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
                return .doNothing
            }
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
