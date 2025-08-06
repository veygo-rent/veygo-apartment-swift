//
//  EmailView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//
import SwiftUI

struct EmailView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @State private var email: String = ""
    @State private var descriptions: [(String, Bool)] = [
        ("Your email has to be in the correct format", false),
        ("You must enroll in a participating university", false),
        ("Your email will also be used for communication of important account updates.", false)
    ]
    @Binding var signup: SignupSession
    @Binding var path: NavigationPath

    @State private var acceptedDomains: [String] = []
    @State private var isAcceptedDomain: Bool? = nil

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
        .modifier(BackButtonHiddenModifier())
        .onAppear() {
            Task {
                await ApiCallActor.shared.appendApi { token, userId in
                    await fetchAcceptedDomainsAsync(token, userId)
                }
            }
            if let email = signup.student_email {
                self.email = email
                self.descriptions[1].1 = false
            }
        }
        .swipeBackGesture {
            path.removeLast()
        }
    }

    private var canProceed: Bool {
        EmailValidator(email: email, acceptedDomains: acceptedDomains).isValidEmail && (isAcceptedDomain ?? false)
    }
    
    @ApiCallActor func fetchAcceptedDomainsAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let request = veygoCurlRequest(
                url: "/api/v1/apartment/get-universities",
                method: .get
            )
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
                nonisolated struct FetchSuccessBody: Decodable {
                    let universities: [Apartment]
                }
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(FetchSuccessBody.self, from: data) else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                let domains = decodedBody.universities.map { uni in
                    uni.acceptedSchoolEmailDomain
                }
                await MainActor.run {
                    self.acceptedDomains = domains
                }
            case 405:
                await MainActor.run {
                    alertTitle = "Internal Error"
                    alertMessage = "Method not allowed, please contact the developer dev@veygo.rent"
                    showAlert = true
                }
            default:
                await MainActor.run {
                    alertTitle = "Application Error"
                    alertMessage = "Unrecognized response, make sure you are running the latest version"
                    showAlert = true
                }
            }
            return .doNothing
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
