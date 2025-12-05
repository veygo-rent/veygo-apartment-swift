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
    case submitFile
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
        if session.user == nil {
            EmptyView()
        } else {
            NavigationStack (path: $path) {
                List {
                    Section {
                        NavigationLink("Membership", value: SettingDestination.membership)
                        NavigationLink("Wallet", value: SettingDestination.wallet)
                        if !session.user!.phoneIsVerified {
                            NavigationLink("Verify Phone Number", value: SettingDestination.phone)
                        }
                        if let email_exp_str = session.user!.studentEmailExpiration,
                           let email_exp = VeygoDatetimeStandard.shared.yyyyMMddDateFormatter.date(from: email_exp_str) {
                            if Date() > email_exp {
                                NavigationLink("Verify Your Email", value: SettingDestination.email)
                            }
                        } else {
                            NavigationLink("Verify Your Email", value: SettingDestination.email)
                        }
                        NavigationLink("Password", value: SettingDestination.password)
                        NavigationLink("Submit Documents", value: SettingDestination.submitFile)
                    } header: {
                        Text("Account")
                            .fontWeight(.light)
                    }
                    .listRowBackground(Color("CardBG"))
                    .foregroundStyle(Color("TextBlackSecondary"))
                    .listSectionSeparator(.hidden)
                    
                    Section {
                        NavigationLink("Privacy Policy", value: SettingDestination.privacyPolicy)
                        NavigationLink("Member Agreement", value: SettingDestination.memberAgreement)
                        NavigationLink("Rental Agreement", value: SettingDestination.rentalAgreement)
                        NavigationLink("Terms of Use", value: SettingDestination.termsOfUse)
                    } header: {
                        Text("Legal")
                            .fontWeight(.light)
                    }
                    .listRowBackground(Color("CardBG"))
                    .foregroundStyle(Color("TextBlackSecondary"))
                    .listSectionSeparator(.hidden)
                    
                    Section {
                        NavigationLink("Roadside Assistance", value: SettingDestination.roadside)
                        Button {
                            showHelpCenter.toggle()
                        } label: {
                            Text("Help Center")
                        }
                    } header: {
                        Text("Support")
                            .fontWeight(.light)
                    }
                    .listRowBackground(Color("CardBG"))
                    .foregroundStyle(Color("TextBlackSecondary"))
                    .listSectionSeparator(.hidden)
                    
                    
                    Section {
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
                    }
                    .listRowBackground(Color("CardBG"))
                    .listSectionSeparator(.hidden)
                }
                .listStyle(.automatic)
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
                    case .submitFile:
                        SubmitFileView(path: $path)
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
