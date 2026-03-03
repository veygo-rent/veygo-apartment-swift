enum RootDestination: String, Identifiable, Hashable {
    case home, trips, reward, setting

    var id: String { self.rawValue }
}

import SwiftUI

struct TabBar: View {
    
    @State private var selected: RootDestination = .home
    
    private let homeImg = "sparkle.text.clipboard"
    private let tripsImg = "map"
    private let rewardImg = "trophy"
    private let settingImg = "gearshape"
    
    @State private var universities: [Apartment] = []
    @State private var cards: [PublishPaymentMethod] = []
    @State private var settingPath: [SettingDestination] = []
    
    var body: some View {
        TabView(selection: $selected) {
            Tab(value: .home) {
                HomeView(universities: $universities)
                    .background(Color("MainBG").ignoresSafeArea())
            } label: {
                Label("Book", systemImage: homeImg)
                    .environment(\.symbolVariants, selected == .home ? .fill : .none)
            }
            
            Tab(value: .trips) {
                TripView(selectedTab: $selected)
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
                SettingView(cards: $cards, path: $settingPath)
                    .background(Color("MainBG").ignoresSafeArea())
            } label: {
                Label("Setting", systemImage: settingImg)
                    .environment(\.symbolVariants, selected == .setting ? .fill : .none)
            }

        }
    }
}
