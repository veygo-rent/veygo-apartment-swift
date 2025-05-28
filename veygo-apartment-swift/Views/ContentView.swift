import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: UserSession
    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0

    @State private var shouldShowLogin = false

    var body: some View {
        Group {
            if shouldShowLogin || token.isEmpty {
                ZStack {
                    Color("MainBG")
                        .ignoresSafeArea()
                    LaunchScreenView()
                        .environmentObject(session)
                }
            } else {
                HomeView()
                    .environmentObject(session)
            }
        }
        .onAppear {
            if token.isEmpty {
                print("No token found, showing login screen.")
                shouldShowLogin = true
                return
            }

            // 尝试用 token + userId 验证用户身份
            session.validateTokenAndFetchUser(token: token, userId: userId) { isValid in
                if isValid {
                    print("🔐 Token is valid. Proceeding to home.")
                    DispatchQueue.main.async {
                                    shouldShowLogin = false
                    }
                } else {
                    print("🚪 Token invalid. Redirecting to login.")
                    DispatchQueue.main.async {
                        token = ""
                        session.user = nil
                        shouldShowLogin = true
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserSession())
}
