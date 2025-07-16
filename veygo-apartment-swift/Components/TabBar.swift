private enum Destination: String, Identifiable, Hashable {
    case home, trips, reward, setting

    var id: String { self.rawValue }
}

import SwiftUI

struct TabBar: View {
    @State private var selected: Destination = .home
    private let homeImg = "house"
    private let tripsImg = "map.fill"
    private let rewardImg = "trophy.fill"
    private let settingImg = "gearshape.fill"
    var body: some View {
        if #available(iOS 18, *) {
            TabView(selection: $selected) {
                Tab(value: .home) {
                    HomeView()
                        .background(Color("MainBG").ignoresSafeArea())
                } label: {
                    Label("Home", systemImage: homeImg)
                }
                
                Tab(value: .trips) {
                    TripView()
                        .background(Color("MainBG").ignoresSafeArea())
                } label: {
                    Label("Trips", systemImage: tripsImg)
                }
                
                Tab(value: .reward) {
                    RewardView()
                        .background(Color("MainBG").ignoresSafeArea())
                } label: {
                    Label("Reward", systemImage: rewardImg)
                }
                
                Tab(value: .setting) {
                    SettingView()
                        .background(Color("MainBG").ignoresSafeArea())
                } label: {
                    Label("Setting", systemImage: settingImg)
                }

            }
        } else {
            TabView(selection: $selected) {
                HomeView()
                    .background(Color("MainBG").ignoresSafeArea())
                    .tabItem { Label("Home", systemImage: homeImg) }
                    .tag(Destination.home)

                TripView()
                    .background(Color("MainBG").ignoresSafeArea())
                    .tabItem { Label("Trips", systemImage: tripsImg) }
                    .tag(Destination.trips)

                RewardView()
                    .tabItem { Label("Reward", systemImage: rewardImg) }
                    .tag(Destination.reward)

                SettingView()
                    .background(Color("MainBG").ignoresSafeArea())
                    .tabItem { Label("Setting", systemImage: settingImg) }
                    .tag(Destination.setting)
            }
        }
    }
}


#Preview {
    TabBar().environmentObject(UserSession())
}

