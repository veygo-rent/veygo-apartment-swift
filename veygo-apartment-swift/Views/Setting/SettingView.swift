//
//  SettingView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/18/25.
//

import SwiftUI

struct SettingView: View {
    @EnvironmentObject var session: UserSession
    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0
    @AppStorage("phone_verified_at") var phoneVerifiedAt: Double = 0
    @AppStorage("email_verified_at") var emailVerifiedAt: Double = 0
    
    @State var showAlert: Bool = false
    @State private var phoneVerified: Bool = false
    @State private var emailVerified = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
//                BannerView(showTitle: false, showBackButton: false)
//                    .ignoresSafeArea(.container, edges: .top)
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(session.user?.name ?? "Unknown User")")
                            .font(.system(size: 25, weight: .semibold))
                            .foregroundColor(Color("TextBlackPrimary"))
                        
                        Text("Diamond Member")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color("TextBlackPrimary"))
                        
                        Divider()
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                            .background(Color("SeparateLine"))
                            .ignoresSafeArea(edges: .horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Account Settings")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color("TextBlackPrimary"))
                        
                        Group {
                            SettingsRow(title: "Membership", subtitle: "Diamond Member", showSubtitle: true, showVerification: false)
                            SettingsRow(title: "Wallet", subtitle: "Add or manage payment methods", showSubtitle: true, showVerification: false)
                            NavigationLink(destination: PhoneVeri(isVerified: $phoneVerified)) {
                                SettingsRow(
                                    title: "Phone",
                                    subtitle: session.user?.phone ?? "Unknown",
                                    showSubtitle: true,
                                    showVerification: !phoneVerified 
                                )
                            }
                            NavigationLink(destination: EmailVeri(isVerified: $emailVerified)) {
                                SettingsRow(
                                    title: "Email",
                                    subtitle: session.user?.studentEmail ?? "Not set",
                                    showSubtitle: true,
                                    showVerification: !emailVerified
                                )
                            }
                            SettingsRow(title: "Password", subtitle: nil, showSubtitle: false, showVerification: false)
                            SettingsRow(title: "Driver’s License", subtitle: nil, showSubtitle: false, showVerification: true)
                            SettingsRow(title: "Insurance", subtitle: nil, showSubtitle: false, showVerification: true)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Support")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color("TextBlackPrimary"))
                        
                        SettingsRow(title: "FAQ’s", subtitle: nil, showSubtitle: false, showVerification: false)
                        NavigationLink(destination: ContactView()) {
                            SettingsRow(title: "Contact Us", subtitle: nil, showSubtitle: false, showVerification: false)
                        }
                    }
                    
                    Spacer()
                    
                    PrimaryButtonLg(text: "Log out") {
                        let request = veygoCurlRequest(url: "/api/v1/user/remove-token", method: "GET", headers: ["auth": "\(token)$\(userId)"])
                        URLSession.shared.dataTask(with: request) { data, response, error in
                            guard let httpResponse = response as? HTTPURLResponse else {
                                print("Invalid server response.")
                                return
                            }
                            if httpResponse.statusCode == 200 {
                                token = ""
                                userId = 0
                                DispatchQueue.main.async {
                                    // Update UserSession
                                    self.session.user = nil
                                }
                                print("🧼 Token cleared")
                            }
                        }.resume()
                    }
                    .navigationTitle("Setting")
                    .navigationBarTitleDisplayMode(.inline) //这里可以把root上的改小
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(Color("AccentColor"), for: .navigationBar)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .padding(.top, 15)
            }
        }
        .onAppear {
            let now = Date().timeIntervalSince1970
            phoneVerified = now - phoneVerifiedAt < 30 * 24 * 60 * 60
            emailVerified = now - emailVerifiedAt < 30 * 24 * 60 * 60
        }
    }
}

#Preview {
    SettingView()
        .environmentObject(UserSession())
}

