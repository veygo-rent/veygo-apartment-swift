import SwiftUI

struct PasswordView: View {
    @State private var password: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var goToCongratsView = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    @State private var descriptions: [(String, Bool)] = [
        ("Password must be at least:", false),
        ("· at least 8 digits long", false),
        ("· at least one number and one special character\n  eg. (!@#$%^&*_+=?/~';,<>\u{7C})", false)
    ]

    @EnvironmentObject var signup: SignupSession
    @EnvironmentObject var session: UserSession
    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Button(action: {
                    dismiss()
                }) {
                    BackButton()
                }
                .padding(.top, 90)
                .padding(.leading, 30)

                VStack(alignment: .leading, spacing: 20) {
                    Spacer()

                    LargeTitleText(text: "Keep Your\nAccount Safe")
                        .padding(.bottom, 90)
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(alignment: .leading, spacing: 5) {
                        InputWithLabel(
                            label: "Your Account Password",
                            placeholder: "iloveveygo",
                            text: $password,
                            descriptions: $descriptions
                        )
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    ArrowButton(isDisabled: !isPasswordValid(password)) {
                        signup.password = password
                        registerUser()
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
                CongratsView()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Registration Failed"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Validation Helpers
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

    // MARK: - Register User API
    func registerUser() {
        guard let url = URL(string: "https://dev.veygo.rent/api/v1/user/create") else {
            alertMessage = "Invalid URL"
            showAlert = true
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        guard let dobDate = formatter.date(from: signup.date_of_birth) else {
            alertMessage = "Invalid date format"
            showAlert = true
            return
        }
        formatter.dateFormat = "yyyy-MM-dd"
        let dobFormatted = formatter.string(from: dobDate)

        let body: [String: String] = [
            "name": signup.name,
            "student_email": signup.student_email,
            "password": signup.password,
            "phone": signup.phone,
            "date_of_birth": dobFormatted
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("JSON Body to send:")
            print(jsonString)
        }

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

            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                DispatchQueue.main.async {
                    alertMessage = "Invalid response from server."
                    showAlert = true
                }
                return
            }

            guard httpResponse.statusCode == 201 else {
                DispatchQueue.main.async {
                    if httpResponse.statusCode == 400 {
                        alertMessage = "Some of your registration info may be incorrect."
                    } else if httpResponse.statusCode == 406 {
                        alertMessage = "Invalid email or phone number."
                    } else {
                        alertMessage = "Unexpected error (code: \(httpResponse.statusCode))."
                    }
                    showAlert = true
                }
                return
            }

            let token = httpResponse.value(forHTTPHeaderField: "token") ?? ""

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let renter = json["renter"],
               let renterData = try? JSONSerialization.data(withJSONObject: renter),
               let decodedUser = try? JSONDecoder().decode(PublishRenter.self, from: renterData) {

                DispatchQueue.main.async {
                    session.user = decodedUser
                    self.token = token
                    self.userId = decodedUser.id

                    UserDefaults.standard.set(token, forKey: "token")
                    UserDefaults.standard.set(decodedUser.id, forKey: "user_id")
                    UserDefaults.standard.set(try? JSONEncoder().encode(decodedUser), forKey: "user")

                    print("Registered user: \(decodedUser.name)")
                    print("Token: \(token)")
                    print("User ID: \(decodedUser.id)")
                    goToCongratsView = true
                }
            } else {
                DispatchQueue.main.async {
                    alertMessage = "Failed to decode user data."
                    showAlert = true
                }
            }
        }.resume()
    }
}

#Preview {
    PasswordView()
}
