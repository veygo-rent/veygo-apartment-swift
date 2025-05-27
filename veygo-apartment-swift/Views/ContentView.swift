import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: UserSession
    @AppStorage("token") var token: String = ""

    var body: some View {
        if token.isEmpty {
            ZStack {
                Color("MainBG")
                    .ignoresSafeArea()
                LaunchScreenView()
                    .environmentObject(session)
            }
        } else {
            HomeView()
                .environmentObject(session)
                .onAppear {
                    print("Now we have your token: \(token)")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserSession())
}
