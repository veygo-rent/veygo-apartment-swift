//
//  NotificationManager.swift
//  veygo-apartment-swift
//
//  Created by sardine on 6/18/25.
//
import Foundation
import UserNotifications

struct NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Getting Notificaton Permission")
            } else {
                print("Permission Denied, error: \(error?.localizedDescription ?? "")")
            }
        }
    }

    func sendDraftNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Draft Reminder" //changeable
        content.body = "You have a pending rental. Check it now."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Fail to send notification, error: \(error.localizedDescription)")
            } else {
                print("Notification Send Successfully")
            }
        }
    }
}

