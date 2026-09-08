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

enum HomeDestination: Hashable {
    case university(apartment: Apartment, startDate: Date, endDate: Date, promo: PublishPromo?)
    case apartment
    case vehicleDetails(vehicle: VehicleWithBlockedDurations, location: Location, apartment: Apartment,
                        rateOffer: RateOffer, taxes: [Tax], startDate: Date, endDate: Date, promo: PublishPromo?)
    case summary(vehicle: PublishRenterVehicle, location: Location, apartment: Apartment, rateOffer: RateOffer,
                 mileagePackage: MileagePackage?, promo: PublishPromo?, taxes: [Tax], startDate: Date, endDate: Date)
    case rentalTerms
}

enum SettingDestination: Hashable {
    // Legal
    case privacyPolicy
    case memberAgreement
    case rentalAgreement
    case termsOfUse
    // Admin Support
    case submitVehicleSnapshot // Accessable to none user
    // Support
    case roadside
    // Account Deletion
    case deleteAccount
}

enum AccountDestination: Hashable {
    // Account
    case profile
    case wallet
    case addCard
    case phone
    case email
    case submitFile
}

struct AppView: View {

    @State private var selected: RootDestination = .home
    @State private var router = Router()

    // Shared tab state that used to live in TabBar.
    @State private var universities: [Apartment] = []

    private let homeImg = "sparkle.text.clipboard"
    private let tripsImg = "map"
    private let journeyImg = "sailboat"
    private let accountImg = "person"
    private let settingImg = "gearshape"
    
    private var titleForSelectedTab: String {
        switch selected {
        case .home:    return ""
        case .trips:   return "Trips"
        case .journey: return ""
        case .account: return "Account"
        case .setting: return "Setting"
        }
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            TabView(selection: $selected) {
                Tab(value: RootDestination.home) {
                    HomeView()
                } label: {
                    Label("Book", systemImage: homeImg)
                        .environment(\.symbolVariants, selected == .home ? .fill : .none)
                }

                Tab(value: RootDestination.trips) {
                    TripView(selectedTab: $selected)
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
            .navigationTitle(titleForSelectedTab)
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: HomeDestination.self) { destination in
                homeDestination(destination)
            }
            .navigationDestination(for: SettingDestination.self) { destination in
                settingDestination(destination)
            }
            .navigationDestination(for: AccountDestination.self) { destination in
                accountDestination(destination)
            }
        }
        .environment(router)
    }
    
    @ViewBuilder
    private func homeDestination(_ destination: HomeDestination) -> some View {
        switch destination {
        case .apartment:
            ListCarView()
        case let .university(apartment, startDate, endDate, promo):
            FindCarView(apartment: apartment, startDate: startDate, endDate: endDate, promo: promo)
        case let .vehicleDetails(vehicle, location, apartment, rateOffer, taxes, startDate, endDate, promo):
            VehicleDetailView(startTime: startDate, endTime: endDate, apartment: apartment,
                              vehicleWithBlocksAndLocationInfo: (vehicle, location),
                              taxes: taxes, rateOffer: rateOffer, promo: promo)
        case let .summary(vehicle, location, apartment, rateOffer, mileagePackage, promo, taxes, startDate, endDate):
            SummaryView(startDate: startDate, endDate: endDate, vehicle: vehicle, apartment: apartment,
                        location: location, promo: promo, mileagePackage: mileagePackage,
                        taxes: taxes, rateOffer: rateOffer)
        case .rentalTerms:
            TermsView(term: .rentalAgreement)
        }
    }
    
    @ViewBuilder
    private func settingDestination(_ destination: SettingDestination) -> some View {
        switch destination {
        // Legal
        case .termsOfUse:
            TermsView(term: .termsOfUse)
        case .privacyPolicy:
            TermsView(term: .privacyPolicy)
        case .rentalAgreement:
            TermsView(term: .rentalAgreement)
        case .memberAgreement:
            TermsView(term: .membershipAgreement)
        // Admin Support
        case .submitVehicleSnapshot:
            AdminVehicleSubmissionView()
        // Service
        case .roadside:
            RoadsideView()
        case .deleteAccount:
            DeleteAccountView()
        }
    }

    @ViewBuilder
    private func accountDestination(_ destination: AccountDestination) -> some View {
        switch destination {
        case .addCard:
            FullStripeCardEntryView()
        case .profile:
            EmptyView()
        case .wallet:
            CreditCardView()
        case .phone:
            VerificationView(method: .phone)
        case .email:
            VerificationView(method: .email)
        case .submitFile:
            SubmitFileView()
        }
    }

}
