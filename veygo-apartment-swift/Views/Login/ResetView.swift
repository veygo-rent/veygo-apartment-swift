//
//  ResetView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/13/26.
//

import SwiftUI

struct ResetView: View {
    private enum Field: Hashable {
        case email
        case code
        case newPassword
    }
    @FocusState private var focusedField: Field?

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var toDismiss: Bool = false

    @Environment(\.dismiss) private var dismiss

    let currentEmail: String
    @State private var email: String = ""
    @State private var code: String = ""
    @State private var newPassword: String = ""

    var body: some View {
        VStack(spacing: 20) {
            TextInputField(text: $email, placeholder: "Email")
                .focused($focusedField, equals: .email)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.none)
                .onAppear {
                    email = currentEmail
                }
            HStack(spacing: 16) {
                TextInputField(text: $code, placeholder: "OTP Code")
                    .focused($focusedField, equals: .code)
                SecondaryButton(text: "Send") {
                    Task { await requestCode() }
                }
                .frame(width: 92)
            }
            TextInputField(text: $newPassword, placeholder: "Password", isSecure: true)
                .focused($focusedField, equals: .newPassword)
            PrimaryButton(text: "Reset") {
                Task { await resetPassword() }
            }
        }
        .padding(22)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color("MainBG").ignoresSafeArea().onTapGesture {
            focusedField = nil
        })
        .navigationTitle("Reset Password")
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if toDismiss {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    private func requestCode() async {
        do {
            try await requestPasswordCode()
            present(title: "Request Sent",
                    message: "You should receive an email with an OTP to reset your password.")
        } catch let error as VeygoError {
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func requestPasswordCode() async throws {
        let body = ["email": email]
        let jsonData = try VeygoJsonStandard.shared.encoder.encode(body)

        let request = veygoCurlRequest(url: "/api/v1/verification/request-password-token", method: .post, body: jsonData)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return
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

    private func resetPassword() async {
        do {
            try await resetPasswordCode()
            present(title: "Password Reset",
                    message: "Your password has been reset. You can now log in.",
                    dismissAfter: true)
        } catch let error as VeygoError {
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func resetPasswordCode() async throws {
        let body = [
            "email": email,
            "code": code,
            "new_password": newPassword
        ]
        let jsonData = try VeygoJsonStandard.shared.encoder.encode(body)

        let request = veygoCurlRequest(url: "/api/v1/verification/reset-password", method: .post, body: jsonData)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return
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

    private func present(_ error: ErrorResponse, dismissAfter: Bool = false) {
        present(title: error.title, message: error.message, dismissAfter: dismissAfter)
    }

    private func present(title: String, message: String, dismissAfter: Bool = false) {
        alertTitle = title
        alertMessage = message
        toDismiss = dismissAfter
        showAlert = true
    }
}
