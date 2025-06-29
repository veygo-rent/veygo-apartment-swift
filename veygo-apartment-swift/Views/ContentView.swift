//import SwiftUI
//
//struct ContentView: View {
//    @EnvironmentObject var session: UserSession
//    @AppStorage("token") var token: String = ""
//    @AppStorage("user_id") var userId: Int = 0
//
//    @State private var shouldShowLogin = false
//
//    var body: some View {
//        Group {
//            if shouldShowLogin || token.isEmpty {
//                ZStack {
//                    Color("MainBG")
//                        .ignoresSafeArea()
//                    LaunchScreenView()
//                }
//            } else {
//                HomeView()
//            }
//        }
//        .onAppear {
//            if token.isEmpty {
//                print("No token found, showing login screen.")
//                shouldShowLogin = true
//                return
//            }
//
//            // 尝试用 token + userId 验证用户身份
//            session.validateTokenAndFetchUser(token: token, userId: userId) { isValid in
//                if isValid {
//                    print("🔐 Token is valid. Proceeding to home.")
//                    DispatchQueue.main.async {
//                        shouldShowLogin = false
//                    }
//                } else {
//                    print("🚪 Token invalid. Redirecting to login.")
//                    DispatchQueue.main.async {
//                        token = ""
//                        session.user = nil
//                        shouldShowLogin = true
//                    }
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    ContentView()
//}
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
                            var body: [String: String] = ["apns": apns_token]
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
