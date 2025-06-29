//
//  AppDelegate.swift
//  veygo-apartment-swift
//
//  Created by sardine on 6/19/25.
//
import UIKit
import UserNotifications
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    @AppStorage("apns_token") var apns_token: String = ""

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        if apns_token != token {
            apns_token = token
            #if DEBUG
            apns_token = "!\(token)"
            #endif
        }

        //uploadDeviceTokenToBackend(token: token) //这里上传后端
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Fail to upload token to server: \(error.localizedDescription)")
    }
}

