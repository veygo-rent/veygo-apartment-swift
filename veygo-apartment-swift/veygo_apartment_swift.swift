//
//  veygo_apartment_swiftApp.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 5/13/25.
//

//import SwiftUI
//import Stripe
//
//@main
//struct veygo_apartment_swift: App {
//    init() {
//            StripeAPI.defaultPublishableKey = "pk_live_51QzCjkL87NN9tQEdbASm7SXLCkcDPiwlEbBpOVQk5wZcjOPISrtTVFfK1SFKIlqyoksRIHusp5UcRYJLvZwkyK0a00kdPmuxhM"
//        }
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}
import SwiftUI
import Stripe

@main
struct veygo_apartment_swift: App {
    @StateObject var session = UserSession()
    @StateObject var signupSession = SignupSession()
    @AppStorage("token") var token: String = ""

    init() {
        StripeAPI.defaultPublishableKey = "pk_live_51QzCjkL87NN9tQEdbASm7SXLCkcDPiwlEbBpOVQk5wZcjOPISrtTVFfK1SFKIlqyoksRIHusp5UcRYJLvZwkyK0a00kdPmuxhM"
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)  // 所有页面可访问 session.user
                .environmentObject(signupSession) // 所有页面可访问 signupSession.user
        }
    }
}

