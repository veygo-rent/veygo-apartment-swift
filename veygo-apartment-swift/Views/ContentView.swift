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

    var body: some View {
        ZStack {
            if session.user == nil {
                LoginView()
                    .transition(.move(edge: .leading))
            } else {
                TabBar()
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.bouncy, value: session.user)
        .onChange(of: session.user) { old, new in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
