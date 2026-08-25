//
//  EmailVerifyView.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/21/25.
//

import SwiftUI

struct EmailVerifyView: View {
    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    @State private var verificationCode: String = ""

    var body: some View {
        VStack(spacing: 24) {

            HStack(spacing: 12) {
                InputWithInlinePrompt(userInput: .constant(session.renter?.studentEmail ?? "Not set"), promptText: "Your Email")
                    .disabled(true)
                    .foregroundColor(Color.footNote)

                SecondaryButtonLg(text: "Send") {
                    Task { await sendCode() }
                }
                .frame(width: 120)
            }
            .padding(.top)

            InputWithInlinePrompt(userInput: $verificationCode, promptText: "Verification code")

            HStack {
                PrimaryButtonLg(text: "Verify") {
                    Task { await verify() }
                }
                .frame(maxWidth: .infinity)
            }

            HStack {
                Spacer()
                ShortTextLink(text: "Change Email") {
                    print("User wants to change email")
                }
                Spacer()
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.mainBG.ignoresSafeArea(.all))
        .navigationTitle("Verify Your Email")
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Send code

    private func sendCode() async {
        do {
            try await sendCodeRequest()
            // Success is silent in the original (no confirmation alert).
        } catch let error as VeygoError {
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func sendCodeRequest() async throws {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unknown
        }

        let body = ["verification_method": "Email"]
        let jsonData = try VeygoJsonStandard.shared.encoder.encode(body)
        let request = veygoCurlRequest(
            url: "/api/v1/verification/request-token",
            method: .post,
            headers: ["auth": "\(token)$\(userId)"],
            body: jsonData
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.unauthorized(decodedError)
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

    // MARK: - Verify

    private func verify() async {
        let code = verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else {
            present(title: "Warning", message: "Verification code cannot be empty.")
            return
        }

        do {
            let renter = try await verifyRequest(code: code)
            session.setRenter(renter)   // refresh profile with verified email
            dismiss()
        } catch let error as VeygoError {
            switch error {
            case .unauthorized:
                session.clear()
                present(error.display)
            case .server(let status, _) where status == 406:
                present(title: "Warning", message: "Invalid verification code")
            default:
                present(error.display)
            }
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func verifyRequest(code: String) async throws -> PublishRenter {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unknown
        }

        let body = [
            "verification_method": "Email",
            "code": code
        ]
        let jsonData = try VeygoJsonStandard.shared.encoder.encode(body)
        let request = veygoCurlRequest(
            url: "/api/v1/verification/verify-token",
            method: .post,
            headers: [
                "auth": "\(token)$\(userId)",
                "Content-Type": "application/json"
            ],
            body: jsonData
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return try VeygoJsonStandard.shared.decoder.decode(PublishRenter.self, from: data)
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.unauthorized(decodedError)
            } else {
                // Includes 406 (invalid code) — surfaced specially in verify().
                let decodedError = (try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)) ?? .E_DEFAULT
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
