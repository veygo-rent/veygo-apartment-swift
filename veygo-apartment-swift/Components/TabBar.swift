private enum RootDestination: String, Identifiable, Hashable {
    case home, trips, reward, setting

    var id: String { self.rawValue }
}

import SwiftUI

struct TabBar: View {
    @State private var selected: RootDestination = .home
    private let homeImg = "house"
    private let tripsImg = "map"
    private let rewardImg = "trophy"
    private let settingImg = "gearshape"
    var body: some View {
        if #available(iOS 26, *) {
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
                    .tag(RootDestination.home)

                TripView()
                    .background(Color("MainBG").ignoresSafeArea())
                    .tabItem { Label("Trips", systemImage: tripsImg) }
                    .tag(RootDestination.trips)

                RewardView()
                    .tabItem { Label("Reward", systemImage: rewardImg) }
                    .tag(RootDestination.reward)

                SettingView()
                    .background(Color("MainBG").ignoresSafeArea())
                    .tabItem { Label("Setting", systemImage: settingImg) }
                    .tag(RootDestination.setting)
            }
        }
    }
}


#Preview {
    TabBar().environmentObject(UserSession())
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
