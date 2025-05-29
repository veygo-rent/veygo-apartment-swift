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

    @State private var shouldShowLogin = false
    @State private var userLoaded = false
    @State private var isLoading = true

    var body: some View {
        Group {
            if shouldShowLogin || token.isEmpty {
                LaunchScreenView()
            } else if userLoaded {
                HomeView()
            } else if isLoading {
                ZStack {
                    Color("MainBG")
                        .ignoresSafeArea()
                    LaunchScreenView()
                }
            }
        }
        .onAppear {
            // 第一次启动时打印 token 和 userId
            print("ContentView onAppear")
            print("Token: \(token)")
            print("User ID: \(userId)")

            guard !token.isEmpty else {
                print("🚪 Token is empty. Going to login.")
                shouldShowLogin = true
                isLoading = false
                return
            }

            session.validateTokenAndFetchUser(token: token, userId: userId) { isValid in //这里check token是不是valid。valid就refresh进home，否则进login
                DispatchQueue.main.async {
                    isLoading = false
                    if isValid {
                        print("User loaded. Proceeding to HomeView.")
                        userLoaded = true
                        shouldShowLogin = false
                    } else {
                        print("Token invalid. Going to login.")
                        token = ""
                        session.user = nil
                        shouldShowLogin = true
                    }
                }
            }
        }
    }
}
