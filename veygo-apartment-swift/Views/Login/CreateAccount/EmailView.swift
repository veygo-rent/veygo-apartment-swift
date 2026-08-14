//
//  EmailView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//

import SwiftUI

struct EmailView: View {
    @FocusState private var fieldIsFocused: Bool

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    @State private var email: String = ""
    @State private var descriptions: [(String, Bool)] = [
        ("Your email has to be in the correct format", false),
        ("You must enroll in a participating university", false),
        ("Your email will also be used for communication of important account updates.", false)
    ]
    @State private var signup: NewRenter
    @Binding var path: NavigationPath

    init(renterInfo: NewRenter, path: Binding<NavigationPath>) {
        _signup = State(initialValue: renterInfo)
        _path = path
    }

    @State private var acceptedDomains: [String] = []
    @State private var isAcceptedDomain: Bool? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {

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
                    .focused($fieldIsFocused)
                    .sensoryFeedback(.selection, trigger: fieldIsFocused)
                    .autocorrectionDisabled(true)
                }
                .padding(.horizontal, 32)

                Spacer()

                ArrowButton(isDisabled: !canProceed) {
                    var updated = signup
                    updated.studentEmail = email
                    path.append(SignupRoute.password(renterInfo: updated))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 50)
            }
            .onChange(of: email) { _, newValue in
                email = newValue.lowercased()
                descriptions[0].1 = !EmailValidator(email: email, acceptedDomains: acceptedDomains).isValidEmail
                descriptions[2].1 = false

                let validator = EmailValidator(email: email, acceptedDomains: acceptedDomains)
                isAcceptedDomain = validator.isValidUniversity
                descriptions[1].1 = !validator.isValidUniversity
            }
            .onChange(of: acceptedDomains) { _, _ in
                let validator = EmailValidator(email: email, acceptedDomains: acceptedDomains)
                isAcceptedDomain = validator.isValidUniversity
                descriptions[1].1 = !validator.isValidUniversity
            }
            .padding(.top, 40)
        }
        .background(Color("MainBG"))
        .ignoresSafeArea()
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .task {
            await loadAcceptedDomains()
        }
        .onAppear {
            if let studentEmail = signup.studentEmail {
                email = studentEmail
                descriptions[1].1 = false
            }
        }
        .onTapGesture {
            fieldIsFocused = false
        }
    }

    private var canProceed: Bool {
        EmailValidator(email: email, acceptedDomains: acceptedDomains).isValidEmail && (isAcceptedDomain ?? false)
    }

    // MARK: - Load accepted domains

    private func loadAcceptedDomains() async {
        do {
            acceptedDomains = try await fetchAcceptedDomains()
        } catch let error as VeygoError {
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func fetchAcceptedDomains() async throws -> [String] {
        let request = veygoCurlRequest(
            url: "/api/v1/apartment/get-universities",
            method: .get
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                let decodedApartments = try VeygoJsonStandard.shared.decoder.decode([Apartment].self, from: data)
                return decodedApartments.map { $0.acceptedSchoolEmailDomain }
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
