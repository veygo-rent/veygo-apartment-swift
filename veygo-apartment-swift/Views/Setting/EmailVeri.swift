//
//  EmailVeri.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/21/25.
//

import SwiftUI

struct EmailVeri: View {
    @EnvironmentObject var session: UserSession
    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0

    @State private var verificationCode: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    @Binding var isVerified: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

            HStack(spacing: 12) {
                InputWithInlinePrompt(promptText: "Your Email", userInput: .constant(session.user?.studentEmail ?? "Not set"))
                    .disabled(true)
                    .foregroundColor(Color("FootNote"))

                SecondaryButtonLg(text: "Send Code") {
                    sendVerificationCode()
                }
                .frame(width: 120)
            }

            InputWithInlinePrompt(promptText: "Verification code", userInput: $verificationCode)

            HStack {
                PrimaryButtonLg(text: "Verify") {
                    verifyCode { success in
                        if success {
                            isVerified = true
                        }
                    }
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
        .padding(.horizontal, 24)
        .navigationTitle("Verify Your Email")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color("AccentColor"), for: .navigationBar)
        .alert("Verification", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    func sendVerificationCode() {
        let bodyDict: [String: String] = [
            "verification_method": "Email"
        ]

        guard let body = try? JSONEncoder().encode(bodyDict) else {
            alertMessage = "Failed to encode request body"
            showAlert = true
            return
        }

        let request = veygoCurlRequest(
            url: "/api/v1/verification/request-token",
            method: "POST",
            headers: [
                "auth": "\(token)$\(userId)"
            ],
            body: body
        )

        print("Sending email code with auth header: \(token)$\(userId)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                alertMessage = "Failed to send code: \(error.localizedDescription)"
                showAlert = true
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                alertMessage = "Invalid server response"
                showAlert = true
                return
            }

            if let data = data {
                let responseString = String(data: data, encoding: .utf8) ?? ""
                print("Response from request-token:\n\(responseString)")

                if let newToken = httpResponse.value(forHTTPHeaderField: "token") {
                    print("Updated token from response header: \(newToken)")
                    DispatchQueue.main.async {
                        self.token = newToken
                    }
                }
            }

            DispatchQueue.main.async {
                if httpResponse.statusCode == 200 {
                    alertMessage = "Code sent successfully"
                } else {
                    alertMessage = "Failed to send code (status \(httpResponse.statusCode))"
                }
                showAlert = true
            }
        }.resume()
    }

    func verifyCode(completion: @escaping (Bool) -> Void) {
        guard !verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Verification code cannot be empty."
            showAlert = true
            completion(false)
            return
        }

        let bodyDict: [String: String] = [
            "verification_method": "Email",
            "code": verificationCode
        ]

        guard let body = try? JSONEncoder().encode(bodyDict) else {
            alertMessage = "Failed to encode verification request"
            showAlert = true
            completion(false)
            return
        }

        let request = veygoCurlRequest(
            url: "/api/v1/verification/verify-token",
            method: "POST",
            headers: [
                "auth": "\(token)$\(userId)",
                "Content-Type": "application/json"
            ],
            body: body
        )

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    alertMessage = "Verification failed: \(error.localizedDescription)"
                    showAlert = true
                    completion(false)
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    alertMessage = "Invalid server response"
                    showAlert = true
                    completion(false)
                }
                return
            }

            DispatchQueue.main.async {
                if httpResponse.statusCode == 200 {
                    alertMessage = "Verification successful!"
                    showAlert = true
                    completion(true)
                } else {
                    alertMessage = "Verification failed."
                    showAlert = true
                    completion(false)
                }
            }
        }.resume()
    }
}

#Preview {
    EmailVeri(isVerified: .constant(false))
        .environmentObject(UserSession())
}

