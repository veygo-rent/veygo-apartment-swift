import SwiftUI

/// Result of a successful registration: the auth token plus the created renter.
struct RegisteredRenter: Hashable {
    let token: String
    let renter: PublishRenter
}

struct PasswordView: View {
    @Environment(Session.self) private var session

    @FocusState private var fieldIsFocused: Bool

    @State private var registered: RegisteredRenter? = nil

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    @State private var password: String = ""

    @State private var descriptions: [(String, Bool)] = [
        ("Password must be at least:", false),
        ("· at least 8 digits long", false),
        ("· at least one number and one special character\n  eg. (!@#$%^&*_+=?/~';,<>\u{7C})", false)
    ]
    @State private var signup: NewRenter
    @Binding var path: NavigationPath

    init(renterInfo: NewRenter, path: Binding<NavigationPath>) {
        _signup = State(initialValue: renterInfo)
        _path = path
    }

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
                    Task { await register() }
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
        .background(Color.mainBG)
        .ignoresSafeArea()
        .navigationDestination(item: $registered) { info in
            CongratsView(user: info)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onTapGesture {
            fieldIsFocused = false
        }
    }

    // MARK: - Validation

    private func containsNumber(_ text: String) -> Bool {
        NSPredicate(format: "SELF MATCHES %@", ".*[0-9].*").evaluate(with: text)
    }

    private func containsSpecialChar(_ text: String) -> Bool {
        NSPredicate(format: "SELF MATCHES %@", ".*[!@#$%^&*()_+=?/~';,<>\\|].*").evaluate(with: text)
    }

    private func isPasswordValid(_ password: String) -> Bool {
        password.count >= 8 && containsNumber(password) && containsSpecialChar(password)
    }

    // MARK: - Register

    private func register() async {
        do {
            let result = try await registerUser()
            registered = result   // drives navigation to CongratsView
        } catch let error as VeygoError {
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func registerUser() async throws -> RegisteredRenter {
        guard let dobUsFormat = signup.dateOfBirth,
              let dobDate = VeygoDatetimeStandard.shared.usStandardDateFormatter.date(from: dobUsFormat) else {
            throw VeygoError.unknown
        }

        let dob = VeygoDatetimeStandard.shared.yyyyMMddDateFormatter.string(from: dobDate)
        let body = [
            "name": signup.name ?? "",
            "student_email": signup.studentEmail ?? "",
            "password": signup.password ?? "",
            "phone": signup.phone ?? "",
            "date_of_birth": dob
        ]
        let jsonData = try VeygoJsonStandard.shared.encoder.encode(body)
        let request = veygoCurlRequest(url: "/api/v1/user/create", method: .post, body: jsonData)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 201 {
                let token = extractToken(from: response, for: "Registering user") ?? ""
                let decodedRenter = try VeygoJsonStandard.shared.decoder.decode(PublishRenter.self, from: data)
                guard !token.isEmpty else {
                    throw VeygoError.unknown
                }
                return RegisteredRenter(token: token, renter: decodedRenter)
            } else {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.server(status: httpCode, error: decodedError)
            }
        } catch let error as URLError {
            throw VeygoError.network(error)
        } catch _ as DecodingError {
            throw VeygoError.decoding
        } catch let error as VeygoError {
            throw error
        } catch {
            throw VeygoError.unknown
        }
    }

    // MARK: - Alert

    private func present(_ error: ErrorResponse) {
        present(title: error.title, message: error.message)
    }

    private func present(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
