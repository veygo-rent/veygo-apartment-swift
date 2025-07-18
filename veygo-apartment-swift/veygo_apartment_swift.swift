//
//  veygo_apartment_swiftApp.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 5/13/25.
//
import SwiftUI
import Stripe
import GooglePlacesSwift

@main
struct veygo_apartment_swift: App {
    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0
    @StateObject var session = UserSession()
    
    @State private var didLoad = false

    init() {
        guard let stripeApiKey = ProcessInfo.processInfo.environment["STRIPE_API_KEY"] else {
            fatalError("Missing STRIPE_API_KEY")
        }
        guard let googlePlacesApiKey = ProcessInfo.processInfo.environment["GOOGLE_PLACES_API_KEY"] else {
            fatalError("Missing GOOGLE_PLACES_API_KEY")
        }
        StripeAPI.defaultPublishableKey = stripeApiKey
        let _ = PlacesClient.provideAPIKey(googlePlacesApiKey)
    }

    var body: some Scene {
        WindowGroup {
            LaunchScreenView(didLoad: $didLoad) {
                ContentView()
            }
            .onAppear() {
                session.validateTokenAndFetchUser { completion in
                    // do someting if pull successfully
                }
                didLoad.toggle()
            }
            .onChange(of: token) { oldValue, newValue in
            }
        }
        .environmentObject(session)
    }
}
