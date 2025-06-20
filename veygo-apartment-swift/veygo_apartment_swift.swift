//
//  veygo_apartment_swiftApp.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 5/13/25.
//
import SwiftUI
import Stripe

@main
struct veygo_apartment_swift: App {
    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0
    @StateObject var session = UserSession()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var didLoad = false

    init() {
        StripeAPI.defaultPublishableKey = "pk_live_51QzCjkL87NN9tQEdbASm7SXLCkcDPiwlEbBpOVQk5wZcjOPISrtTVFfK1SFKIlqyoksRIHusp5UcRYJLvZwkyK0a00kdPmuxhM"
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
