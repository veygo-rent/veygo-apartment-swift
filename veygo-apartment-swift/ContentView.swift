import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var session: UserSession

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
        .background(Color("MainBG").ignoresSafeArea())
        .animation(.bouncy, value: session.user)
        .onChange(of: session.user) { old, new in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
}
