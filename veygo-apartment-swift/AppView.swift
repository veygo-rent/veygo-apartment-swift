//
//  AppView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/13/26.
//

import SwiftUI

enum RootDestination: String, Identifiable, Hashable {
    case home, trips, journey, account, setting
    var id: String { rawValue }
}

struct AppView: View {

    @State private var selected: RootDestination = .home
    @State private var path = NavigationPath()

    // Shared tab state that used to live in TabBar.
    @State private var universities: [Apartment] = []

    private let homeImg = "sparkle.text.clipboard"
    private let tripsImg = "map"
    private let journeyImg = "sailboat"
    private let accountImg = "person"
    private let settingImg = "gearshape"

    var body: some View {
        NavigationStack(path: $path) {
            TabView(selection: $selected) {
                Tab(value: RootDestination.home) {
                    HomeView()
                } label: {
                    Label("Book", systemImage: homeImg)
                        .environment(\.symbolVariants, selected == .home ? .fill : .none)
                }

                Tab(value: RootDestination.trips) {
                    TripView()
                } label: {
                    Label("Trips", systemImage: tripsImg)
                        .environment(\.symbolVariants, selected == .trips ? .fill : .none)
                }

                #if DEBUG
                Tab(value: RootDestination.journey) {
                    RewardView()
                } label: {
                    Label("Journey", systemImage: journeyImg)
                        .environment(\.symbolVariants, selected == .journey ? .fill : .none)
                }
                #endif // DEBUG

                Tab(value: RootDestination.account) {
                    AccountView()
                } label: {
                    Label("Account", systemImage: accountImg)
                        .environment(\.symbolVariants, selected == .account ? .fill : .none)
                }

                Tab(value: RootDestination.setting) {
                    SettingView()
                } label: {
                    Label("Setting", systemImage: settingImg)
                        .environment(\.symbolVariants, selected == .setting ? .fill : .none)
                }
            }
//            .navigationDestination(for: AccountDestination.self) { destination in
//                accountDestination(destination)
//            }
//            .navigationDestination(for: SettingDestination.self) { destination in
//                settingDestination(destination)
//            }
        }
    }

//    @ViewBuilder
//    private func accountDestination(_ destination: AccountDestination) -> some View {
//        switch destination {
//        // case .editProfile: EditProfileView()
//        // case .paymentMethods: CreditCardView()
//        default: EmptyView()
//        }
//    }
//
//    @ViewBuilder
//    private func settingDestination(_ destination: SettingDestination) -> some View {
//        switch destination {
//        // case .terms: TermsView(term: .termsOfUse)
//        // case .verifyEmail: EmailVerifyView()
//        default: EmptyView()
//        }
//    }
}
