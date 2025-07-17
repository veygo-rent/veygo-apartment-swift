private enum Destination: String, Identifiable, Hashable {
    case home, trips, reward, setting

    var id: String { self.rawValue }
}

import SwiftUI

struct TabBar: View {
    @State private var selected: Destination = .home
    private let homeImg = "house"
    private let tripsImg = "map"
    private let rewardImg = "trophy"
    private let settingImg = "gearshape"
    var body: some View {
        if #available(iOS 18, *) {
            TabView(selection: $selected) {
                Tab(value: .home) {
                    HomeView()
                        .background(Color("MainBG").ignoresSafeArea())
                } label: {
                    Label("Home", systemImage: homeImg)
                        .environment(\.symbolVariants, selected == .home ? .fill : .none)
                }
                
                Tab(value: .trips) {
                    TripView()
                        .background(Color("MainBG").ignoresSafeArea())
                } label: {
                    Label("Trips", systemImage: tripsImg)
                        .environment(\.symbolVariants, selected == .trips ? .fill : .none)
                }
                
                Tab(value: .reward) {
                    RewardView()
                        .background(Color("MainBG").ignoresSafeArea())
                } label: {
                    Label("Reward", systemImage: rewardImg)
                        .environment(\.symbolVariants, selected == .reward ? .fill : .none)
                }
                
                Tab(value: .setting) {
                    SettingView()
                        .background(Color("MainBG").ignoresSafeArea())
                } label: {
                    Label("Setting", systemImage: settingImg)
                        .environment(\.symbolVariants, selected == .setting ? .fill : .none)
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
