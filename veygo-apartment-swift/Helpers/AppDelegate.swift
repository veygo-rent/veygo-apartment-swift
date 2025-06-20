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
        apns_token = token

        //uploadDeviceTokenToBackend(token: token) //这里上传后端
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Fail to upload token to server: \(error.localizedDescription)")
    }

//    func uploadDeviceTokenToBackend(token: String) {
//        guard let url = URL(string: "https://your-backend.com/api/v1/user/device-token") else { return } //fake url for save token to server
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("Bearer \(UserDefaults.standard.string(forKey: "token") ?? "")", forHTTPHeaderField: "Authorization")
//
//        let body: [String: Any] = [
//            "deviceToken": token,
//            "userId": UserDefaults.standard.integer(forKey: "user_id")
//        ] 
//        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
//
//        URLSession.shared.dataTask(with: request).resume()
//    }
}

