//
//  SettingView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/18/25.
//

import SwiftUI
import Crisp
import _WebKit_SwiftUI

enum SettingDestination: Hashable {
    // Account
    case membership
    case wallet
    case addCard
    case phone
    case email
    case password
    case driversLicense
    case leaseAgreement // Optional
    // Legal
    case privacyPolicy
    case memberAgreement
    case rentalAgreement
    case termsOfUse
    // Support
    case roadside
}

struct SettingView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @State private var showHelpCenter: Bool = false
    
    @Binding var cards: [PublishPaymentMethod]
    @Binding var path: [SettingDestination]
    
    @EnvironmentObject var session: UserSession
    var body: some View {
        NavigationStack (path: $path) {
            List {
                Section {
                    NavigationLink("Membership", value: SettingDestination.membership)
                        .foregroundStyle(Color("TextBlackSecondary"))
                        .listRowBackground(Color("MainBG"))
                        .listRowSeparator(.hidden, edges: .top)
                    NavigationLink("Wallet", value: SettingDestination.wallet)
                        .foregroundStyle(Color("TextBlackSecondary"))
                        .listRowBackground(Color("MainBG"))
                    NavigationLink("Phone", value: SettingDestination.phone)
                        .foregroundStyle(Color("TextBlackSecondary"))
                        .listRowBackground(Color("MainBG"))
                    NavigationLink("Email", value: SettingDestination.email)
                        .foregroundStyle(Color("TextBlackSecondary"))
                        .listRowBackground(Color("MainBG"))
                    NavigationLink("Password", value: SettingDestination.password)
                        .foregroundStyle(Color("TextBlackSecondary"))
                        .listRowBackground(Color("MainBG"))
                    NavigationLink("Drivers License", value: SettingDestination.driversLicense)
                        .foregroundStyle(Color("TextBlackSecondary"))
                        .listRowBackground(Color("MainBG"))
                    NavigationLink("Lease Agreement", value: SettingDestination.leaseAgreement)
                        .foregroundStyle(Color("TextBlackSecondary"))
                        .listRowBackground(Color("MainBG"))
                        .listRowSeparator(.hidden, edges: .bottom)
                }
                .listRowSeparatorTint(Color("SeperatorLine"))
                
                Section {
                    NavigationLink("Privacy Policy", value: SettingDestination.privacyPolicy)
                        .foregroundStyle(Color("TextBlackSecondary"))
                        .listRowBackground(Color("MainBG"))
                        .listRowSeparator(.hidden, edges: .top)
                    NavigationLink("Member Agreement", value: SettingDestination.memberAgreement)
                        .foregroundStyle(Color("TextBlackSecondary"))
                        .listRowBackground(Color("MainBG"))
                    NavigationLink("Rental Agreement", value: SettingDestination.rentalAgreement)
                        .foregroundStyle(Color("TextBlackSecondary"))
                        .listRowBackground(Color("MainBG"))
                    NavigationLink("Terms of Use", value: SettingDestination.termsOfUse)
                        .foregroundStyle(Color("TextBlackSecondary"))
                        .listRowBackground(Color("MainBG"))
                        .listRowSeparator(.hidden, edges: .bottom)
                }
                .listRowSeparatorTint(Color("SeperatorLine"))
                
                Section {
                    NavigationLink("Roadside Assistance", value: SettingDestination.roadside)
                        .foregroundStyle(Color("TextBlackSecondary"))
                        .listRowBackground(Color("MainBG"))
                        .listRowSeparator(.hidden, edges: .all)
                }
                .listRowSeparatorTint(Color("SeperatorLine"))
                
             
                Section {
                    Button {
                        showHelpCenter.toggle()
                    } label: {
                        Text("Help Center")
                            .foregroundStyle(Color("TextBlackPrimary"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .listRowBackground(Color("MainBG"))
                    .listRowSeparator(.hidden, edges: .top)

                    Button(role: .destructive) {
                        Task {
                            await ApiCallActor.shared.appendApi { token, userId in
                                await logoutRequestAsync(token, userId)
                            }
                        }
                    } label: {
                        Text("Log Out")
                            .foregroundStyle(Color("InvalidRed"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .listRowBackground(Color("MainBG"))
                    .listRowSeparator(.hidden, edges: .bottom)
                }
                .listRowSeparatorTint(Color("SeperatorLine"))
            }
            .listStyle(.grouped)
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
            .navigationTitle(Text("Setting"))
            .navigationDestination(for: SettingDestination.self) { destination in
                switch destination {
                case .memberAgreement:
                    WebView(url: URL(string: "https://dev.veygo.rent/membership"))
                case .rentalAgreement:
                    WebView(url: URL(string: "https://dev.veygo.rent/rental-agreement"))
                case .privacyPolicy:
                    WebView(url: URL(string: "https://dev.veygo.rent/privacy"))
                case .wallet:
                    CreditCardView(cards: $cards, path: $path)
                case .addCard:
                    FullStripeCardEntryView(path: $path)
                case .phone:
                    PhoneVerifyView(path: $path)
                case .email:
                    EmailVerifyView(path: $path)
                default:
                    EmptyView()
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") {
                    if clearUserTriggered {
                        session.user = nil
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
        .sheet(isPresented: $showHelpCenter) {
            ChatView()
        }
    }
    
    @ApiCallActor func logoutRequestAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                let request = veygoCurlRequest(url: "/api/v1/user/remove-token", method: .get, headers: ["auth": "\(token)$\(userId)"])
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid protocol"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                switch httpResponse.statusCode {
                case 200:
                    await MainActor.run {
                        session.user = nil
                    }
                    return .clearUser
                case 405:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E405
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    }
                    return .doNothing
                default:
                    let body = ErrorResponse.E_DEFAULT
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                    return .doNothing
                }
            }
            return .doNothing
        } catch {
            await MainActor.run {
                alertTitle = "Internal Error"
                alertMessage = "\(error.localizedDescription)"
                showAlert = true
            }
            return .doNothing
        }
    }
}
