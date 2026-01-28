//
//  PhoneVeri.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/16/25

import SwiftUI

struct PhoneVerifyView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @EnvironmentObject var session: UserSession

    @State private var verificationCode: String = ""
    @Binding var path: [SettingDestination]
    
    var body: some View {
        VStack(spacing: 24) {

            HStack(spacing: 12) {
                InputWithInlinePrompt(promptText: "Your Phone number", userInput: .constant(session.user?.phone ?? "Not set"))
                    .disabled(true)
                    .foregroundColor(Color("FootNote"))

                SecondaryButtonLg(text: "Send Code") {
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await sendVerificationCodeAsync(token, userId)
                        }
                    }
                }
                .frame(width: 120)
            }
            .padding(.top)

            InputWithInlinePrompt(promptText: "Verification code", userInput: $verificationCode)

            HStack {
                PrimaryButtonLg(text: "Verify") {
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await verifyCodeAsync(token, userId)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }

            HStack {
                Spacer()
                ShortTextLink(text: "Change Phone Number") {
                    print("User wants to change phone number")
                }
                Spacer()
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color("MainBG").ignoresSafeArea(.all))
        .navigationTitle("Verify Phone Number")
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if clearUserTriggered {
                    session.user = nil
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    @ApiCallActor func sendVerificationCodeAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                let body: [String: String] = [
                    "verification_method": "Phone"
                ]
                let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(body)
                let request = veygoCurlRequest(
                    url: "/api/v1/verification/request-token",
                    method: .post,
                    headers: [
                        "auth": "\(token)$\(userId)"
                    ],
                    body: jsonData
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
                    return .doNothing
                case 401:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E401
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    }
                    return .clearUser
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
                default:
                    let body = ErrorResponse.E_DEFAULT
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                    return .doNothing
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
    
    @ApiCallActor func verifyCodeAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                let verificationCode = await verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !verificationCode.isEmpty else {
                    await MainActor.run {
                        alertTitle = "Warning"
                        alertMessage = "Verification code cannot be empty."
                        showAlert = true
                    }
                    return .doNothing
                }

                let body: [String: String] = [
                    "verification_method": "Phone",
                    "code": verificationCode
                ]
                let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(body)
                let request = veygoCurlRequest(
                    url: "/api/v1/verification/verify-token",
                    method: .post,
                    headers: [
                        "auth": "\(token)$\(userId)",
                        "Content-Type": "application/json"
                    ],
                    body: jsonData
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
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(PublishRenter.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        path.removeLast()
                        session.user = decodedBody
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
                    await MainActor.run {
                        alertTitle = "Warning"
                        alertMessage = "Invalid verification code"
                        showAlert = true
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
