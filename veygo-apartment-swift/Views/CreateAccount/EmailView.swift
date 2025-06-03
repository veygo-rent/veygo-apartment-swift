//
//  EmailView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//
import SwiftUI

struct EmailView: View {
    @State private var email: String = ""
    @State private var descriptions: [(String, Bool)] = [
        ("Your email has to be in the correct format", false),
        ("You must enroll in a participating university", false),
        ("Your email will also be used for communication of important account updates.", false)
    ]
    @ObservedObject var signup: SignupSession
    @Binding var path: NavigationPath

    @State private var acceptedDomains: [String] = []
    @State private var isAcceptedDomain: Bool? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            EnableSwipeBackGesture() 
            Button(action: {
                path.removeLast()
            }) {
                BackButton()
            }
            .padding(.top, 90)
            .padding(.leading, 30)

            VStack(alignment: .leading, spacing: 20) {
                Spacer()

                LargeTitleText(text: "Send Letters\nThe Old Way")
                    .padding(.bottom, 90)
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: 5) {
                    InputWithLabel(
                        label: "Your School Email",
                        placeholder: "info@veygo.rent",
                        text: $email,
                        descriptions: $descriptions
                    )
                }
                .padding(.horizontal, 32)

                Spacer()

                ArrowButton(isDisabled: !canProceed) {
                    signup.student_email = email
                    path.append(SignupRoute.password)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 50)
            }
            .onChange(of: email) { oldValue, newValue in
                email = newValue.lowercased()
                descriptions[0].1 = !EmailValidator(email: email, acceptedDomains: acceptedDomains).isValidEmail
                descriptions[2].1 = false

                let validator = EmailValidator(email: email, acceptedDomains: acceptedDomains)
                isAcceptedDomain = validator.isValidUniversity
                descriptions[1].1 = !validator.isValidUniversity
            }
            .onChange(of: acceptedDomains, { oldValue, newValue in
                let validator = EmailValidator(email: email, acceptedDomains: acceptedDomains)
                isAcceptedDomain = validator.isValidUniversity
                descriptions[1].1 = !validator.isValidUniversity
            })
            .padding(.top, 40)
        }
        .background(Color("MainBG"))
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .onAppear() {
            fetchAcceptedDomains()
            if let email = signup.student_email {
                self.email = email
                self.descriptions[1].1 = false
            }
        }
    }

    private var canProceed: Bool {
        EmailValidator(email: email, acceptedDomains: acceptedDomains).isValidEmail && (isAcceptedDomain ?? false)
    }

    private func fetchAcceptedDomains() {
        let request = veygoCurlRequest(
            url: "/api/v1/apartment/get-universities",
            method: "GET"
        )

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received.")
                return
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response:\n\(jsonString)")
            }

            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let universities = jsonObject["universities"] as? [[String: Any]] {

                    let domains = universities.compactMap { uni in
                        uni["accepted_school_email_domain"] as? String
                    }

                    DispatchQueue.main.async {
                        self.acceptedDomains = domains
                        print("Parsed accepted domains: \(domains)")
                    }

                } else {
                    print("Failed to parse 'universities' from JSON.")
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }.resume()
    }
}

#Preview {
    EmailView(signup: .init(), path: .constant(.init()))
}
