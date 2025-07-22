import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: UserSession
    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0
    @AppStorage("apns_token") var apns_token: String = ""
    @AppStorage("prev_apns_token") var prev_apns_token: String = ""

    var body: some View {
        ZStack {
            if session.user == nil {
                LoginView()
                    .transition(.move(edge: .leading))
            } else {
                TabBar()
                    .onAppear {
                        NotificationManager.shared.requestPermission()
                        if !apns_token.isEmpty && apns_token != prev_apns_token {
                            prev_apns_token = apns_token
                            let body: [String: String] = ["apns": apns_token]
                            let jsonData = try? JSONSerialization.data(withJSONObject: body)
                            let update_apns_request = veygoCurlRequest(url: "/api/v1/user/update-apns", method: "POST", headers: ["auth": "\(token)$\(userId)"], body: jsonData)
                            URLSession.shared.dataTask(with: update_apns_request) { data, response, error in
                                guard let httpResponse = response as? HTTPURLResponse else {
                                    print("Invalid server response.")
                                    return
                                }
                                if httpResponse.statusCode == 200 {
                                    self.token = extractToken(from: response)!
                                    print("APNs Updated")
                                }
                            }.resume()
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
}
