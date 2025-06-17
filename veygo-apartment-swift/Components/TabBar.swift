enum Destination: String, Identifiable, Hashable {
    case home, trips, reward, setting

    var id: String { self.rawValue }
}

import SwiftUI

struct TabBar: View {
    @State var selected: Destination = .home
    private let homeImg = "house"
    private let tripsImg = "map.fill"
    private let rewardImg = "trophy.fill"
    private let settingImg = "gearshape.fill"
    var body: some View {
        if #available(iOS 18, *) {
            TabView(selection: $selected) {
                Tab(value: .home) {
                    HomeView()
                } label: {
                    Label("Home", systemImage: homeImg)
                }
                
                Tab(value: .trips) {
                    Trips()
                } label: {
                    Label("Trips", systemImage: tripsImg)
                }
                
                Tab(value: .reward) {
                    Text("Reward View")
                } label: {
                    Label("Reward", systemImage: rewardImg)
                }
                
                Tab(value: .setting) {
                    Setting()
                } label: {
                    Label("Setting", systemImage: settingImg)
                }

            }
        } else {
            TabView(selection: $selected) {
                HomeView()
                    .tabItem { Label("Home", systemImage: homeImg) }
                    .tag(Destination.home)

                Trips()
                    .tabItem { Label("Trips", systemImage: tripsImg) }
                    .tag(Destination.trips)

                Text("Reward View")
                    .tabItem { Label("Reward", systemImage: rewardImg) }
                    .tag(Destination.reward)

                Setting()
                    .tabItem { Label("Setting", systemImage: settingImg) }
                    .tag(Destination.setting)
            }
        }
    }
}


#Preview {
    TabBar().environmentObject(UserSession())
}

