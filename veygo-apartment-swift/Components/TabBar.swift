enum RootDestination: String, Identifiable, Hashable {
    case home, trips, journey, account, setting

    var id: String { self.rawValue }
}

import SwiftUI

struct TabBar: View {
    
    @State private var selected: RootDestination = .home
    
    private let homeImg = "sparkle.text.clipboard"
    private let tripsImg = "map"
    private let journeyImg = "sailboat"
    private let accountImg = "person"
    private let settingImg = "gearshape"
    
    @State private var universities: [Apartment] = []
    @State private var settingPath: [SettingDestination] = []
    @State private var accountPath: [AccountDestination] = []
    
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
            
            #if DEBUG
            Tab(value: .journey) {
                RewardView()
                    .background(Color("MainBG").ignoresSafeArea())
            } label: {
                Label("Journey", systemImage: journeyImg)
                    .environment(\.symbolVariants, selected == .journey ? .fill : .none)
            }
            #endif
            
            Tab(value: .account) {
                AccountView(path: $accountPath)
                    .background(Color("MainBG").ignoresSafeArea())
            } label: {
                Label("Account", systemImage: accountImg)
                    .environment(\.symbolVariants, selected == .account ? .fill : .none)
            }
            
            Tab(value: .setting) {
                SettingView(path: $settingPath)
                    .background(Color("MainBG").ignoresSafeArea())
            } label: {
                Label("Setting", systemImage: settingImg)
                    .environment(\.symbolVariants, selected == .setting ? .fill : .none)
            }

        }
    }
}
