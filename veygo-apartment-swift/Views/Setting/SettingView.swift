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
    @State var showAlert: Bool = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
//                BannerView(showTitle: false, showBackButton: false)
//                    .ignoresSafeArea(.container, edges: .top)
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Xinyi Guan")
                            .font(.system(size: 25, weight: .semibold))
                            .foregroundColor(Color("TextBlackPrimary"))
                        
                        Text("Ascendant Member")
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
                            SettingsRow(title: "Membership", subtitle: "Acendant Member", showSubtitle: true, showVerification: false)
                            SettingsRow(title: "Wallet", subtitle: "Add or manage payment methods", showSubtitle: true, showVerification: false)
                            SettingsRow(title: "Phone", subtitle: "312-810-3169", showSubtitle: true, showVerification: false)
                            SettingsRow(title: "Email", subtitle: "guan90@purdue.edu", showSubtitle: true, showVerification: true)
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
                    
                    LargerPrimaryButtonLg(text: "Log out") {
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
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(
                        Color("Accent2Color").opacity(0.6),
                        for: .navigationBar)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        }
    }
}

#Preview {
    SettingView()
        .environmentObject(UserSession())
}

