//
//  PhoneVeri.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/16/25

import SwiftUI

struct PhoneVeri: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @EnvironmentObject var session: UserSession
    
    @AppStorage("phone_verified_at") var phoneVerifiedAt: Double = 0 // 让need verification消失30天 也就是说30天内用户不用再次验证

    @State private var verificationCode: String = ""
    
    @Binding var isVerified: Bool
    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

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
        .padding(.horizontal, 24)
        .navigationTitle("Verify Your Phone Number")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color("AccentColor"), for: .navigationBar)
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
            if !token.isEmpty && userId > 0 {
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
                let (_, response) = try await URLSession.shared.data(for: request)
                
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
                    let token = extractToken(from: response) ?? ""
                    return .renewSuccessful(token: token)
                case 401:
                    await MainActor.run {
                        alertTitle = "Session Expired"
                        alertMessage = "Token expired, please login again"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
                case 405:
                    await MainActor.run {
                        alertTitle = "Internal Error"
                        alertMessage = "Method not allowed, please contact the developer dev@veygo.rent"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
                default:
                    await MainActor.run {
                        alertTitle = "Application Error"
                        alertMessage = "Unrecognized response, make sure you are running the latest version"
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
            if !token.isEmpty && userId > 0 {
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
                    nonisolated struct FetchSuccessBody: Decodable {
                        let verifiedRenter: PublishRenter
                    }
                    
                    let token = extractToken(from: response) ?? ""
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(FetchSuccessBody.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .renewSuccessful(token: token)
                    }
                    await MainActor.run {
                        session.user = decodedBody.verifiedRenter
                    }
                    return .renewSuccessful(token: token)
                case 405:
                    await MainActor.run {
                        alertTitle = "Internal Error"
                        alertMessage = "Method not allowed, please contact the developer dev@veygo.rent"
                        showAlert = true
                        clearUserTriggered = true
                    }
                    return .clearUser
                case 406:
                    let token = extractToken(from: response) ?? ""
                    await MainActor.run {
                        alertTitle = "Warning"
                        alertMessage = "Invalid verification code"
                        showAlert = true
                    }
                    return .renewSuccessful(token: token)
                default:
                    await MainActor.run {
                        alertTitle = "Application Error"
                        alertMessage = "Unrecognized response, make sure you are running the latest version"
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

#Preview {
    PhoneVeri(isVerified: .constant(false))
        .environmentObject(UserSession())
}

