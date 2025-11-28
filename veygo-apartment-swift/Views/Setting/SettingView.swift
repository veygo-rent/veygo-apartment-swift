//
//  SettingView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/18/25.
//

import SwiftUI
import Crisp

enum SettingDestination: Hashable {
    // Account
    case membership
    case wallet
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
    case helpCenter
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
                        .listRowBackground(Color("MainBG"))
                        .listRowSeparator(.hidden, edges: .top)
                    NavigationLink("Wallet", value: SettingDestination.wallet)
                        .listRowBackground(Color("MainBG"))
                    NavigationLink("Phone", value: SettingDestination.phone)
                        .listRowBackground(Color("MainBG"))
                    NavigationLink("Email", value: SettingDestination.email)
                        .listRowBackground(Color("MainBG"))
                    NavigationLink("Password", value: SettingDestination.password)
                        .listRowBackground(Color("MainBG"))
                    NavigationLink("Drivers License", value: SettingDestination.driversLicense)
                        .listRowBackground(Color("MainBG"))
                    NavigationLink("Lease Agreement", value: SettingDestination.leaseAgreement)
                        .listRowBackground(Color("MainBG"))
                        .listRowSeparator(.hidden, edges: .bottom)
                }
                .listRowSeparatorTint(Color("SeperatorLine"))
                
                Section {
                    NavigationLink("Privacy Policy", value: SettingDestination.privacyPolicy)
                        .listRowBackground(Color("MainBG"))
                        .listRowSeparator(.hidden, edges: .top)
                    NavigationLink("Member Agreement", value: SettingDestination.memberAgreement)
                        .listRowBackground(Color("MainBG"))
                    NavigationLink("Rental Agreement", value: SettingDestination.rentalAgreement)
                        .listRowBackground(Color("MainBG"))
                    NavigationLink("Terms of Use", value: SettingDestination.termsOfUse)
                        .listRowBackground(Color("MainBG"))
                        .listRowSeparator(.hidden, edges: .bottom)
                }
                .listRowSeparatorTint(Color("SeperatorLine"))
                
                Section {
                    NavigationLink("Roadside Assistance", value: SettingDestination.roadside)
                        .listRowBackground(Color("MainBG"))
                        .listRowSeparator(.hidden, edges: .all)
                }
                .listRowSeparatorTint(Color("SeperatorLine"))
                
             
                Section {
                    Text("Help Center")
                        .listRowBackground(Color("MainBG"))
                        .listRowSeparator(.hidden, edges: .top)
                        .onTapGesture {
                            showHelpCenter.toggle()
                        }
                    Button(role: .destructive) {
                        Task {
                            await ApiCallActor.shared.appendApi { token, userId in
                                await logoutRequestAsync(token, userId)
                            }
                        }
                    } label: {
                        Text("Log Out")
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
                default:
                    EmptyView()
                }
            }
        }
        .sheet(isPresented: $showHelpCenter) {
            CrispChatView(
                email: session.user?.studentEmail ?? "",
                phone: session.user?.phone ?? "",
                name: session.user?.name ?? ""
            )
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

struct CrispChatView: UIViewControllerRepresentable {
    let email: String
    let phone: String
    let name: String
    func makeUIViewController(context: Context) -> ChatViewController {
        CrispSDK.user.email = email
        CrispSDK.user.phone = phone
        CrispSDK.user.nickname = name
        return ChatViewController()
    }

    func updateUIViewController(_ uiViewController: ChatViewController, context: Context) {
        // No updates needed
    }
}
