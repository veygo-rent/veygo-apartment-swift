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
    init() {
            StripeAPI.defaultPublishableKey = "pk_live_51QzCjkL87NN9tQEdbASm7SXLCkcDPiwlEbBpOVQk5wZcjOPISrtTVFfK1SFKIlqyoksRIHusp5UcRYJLvZwkyK0a00kdPmuxhM"
        }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
