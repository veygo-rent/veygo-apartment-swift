import SwiftUI

struct ContentView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @EnvironmentObject var session: UserSession
    
    @AppStorage("apns_token") var apns_token: String = ""
    @AppStorage("prev_apns_token") var prev_apns_token: String = ""

    var body: some View {
        ZStack {
            if session.user == nil {
                LoginView()
                    .transition(.move(edge: .leading))
            } else {
                TabBar()
                    .alert(alertTitle, isPresented: $showAlert) {
                        Button("OK") {
                            if clearUserTriggered {
                                session.user = nil
                            }
                        }
                    } message: {
                        Text(alertMessage)
                    }
                    .onAppear {
                        Task {
                            await ApiCallActor.shared.appendApi { token, userId in
                                await updateApnsTokenAsync(token, userId)
                            }
                        }
                    }
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.bouncy, value: session.user)
        .onChange(of: session.user) { old, new in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    @ApiCallActor func updateApnsTokenAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            NotificationManager.shared.requestPermission()
            let apns_token = await apns_token
            let prev_apns_token = await prev_apns_token
            if !apns_token.isEmpty && apns_token != prev_apns_token {
                await MainActor.run {
                    self.prev_apns_token = apns_token
                }
                let body: [String: String] = ["apns": apns_token]
                let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(body)
                let request = veygoCurlRequest(url: "/api/v1/user/update-apns", method: "POST", headers: ["auth": "\(token)$\(userId)"], body: jsonData)
                let (_, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid protocol"
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
}
