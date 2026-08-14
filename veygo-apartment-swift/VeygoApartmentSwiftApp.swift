//
//  VeygoApartmentSwiftApp.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/11/26.
//

import SwiftUI

import UserNotifications

import Crisp
@preconcurrency import Stripe

@main
struct VeygoApartmentSwiftApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate
    
    @State private var session = Session()
    
    init() {
        StripeAPI.defaultPublishableKey = "pk_live_51QzCjkL87NN9tQEdbASm7SXLCkcDPiwlEbBpOVQk5wZcjOPISrtTVFfK1SFKIlqyoksRIHusp5UcRYJLvZwkyK0a00kdPmuxhM"
        CrispSDK.configure(websiteID: "11d81aa1-c3e9-4295-a6ca-b207d63f37de")
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        #if DEBUG
        tokenString = "!\(tokenString)"
        #endif
        UserDefaults.standard.set(tokenString, forKey: "apns_token")
    }
}
