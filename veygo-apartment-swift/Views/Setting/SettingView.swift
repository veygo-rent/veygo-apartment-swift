//
//  SettingView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/18/25.
//

import SwiftUI
import Crisp
import WebKit

enum SettingDestination: Hashable {
    // Legal
    case privacyPolicy
    case memberAgreement
    case rentalAgreement
    case termsOfUse
    // Admin Support
    case submitVehicleSnapshot // Accessable to none user
    // Support
    case roadside
    // Account Deletion
    case deleteAccount
}

struct SettingView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @State private var showHelpCenter: Bool = false
    
    @Binding var path: [SettingDestination]
    
    @EnvironmentObject var session: UserSession
    var body: some View {
        if let user = session.user {
            NavigationStack (path: $path) {
                List {
                    if user.employeeTier != EmployeeTier.user && user.emailIsValid() {
                        Section {
                            NavigationLink("Upload Vehicle Snapshot", value: SettingDestination.submitVehicleSnapshot)
                        } header: {
                            Text("Admin")
                                .fontWeight(.light)
                        }
                        .listRowBackground(Color("CardBG"))
                        .foregroundStyle(Color("TextBlackSecondary"))
                        .listSectionSeparator(.hidden)
                    }
                    
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
                    
                    Section {
                        ShortTextLink(text: "Request deleting account") {
                            path.append(.deleteAccount)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listSectionSeparator(.hidden)
                    .listSectionSpacing(0)
                }
                .listStyle(.automatic)
                .scrollIndicators(.hidden)
                .scrollContentBackground(.hidden)
                .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
                .navigationTitle(Text("Setting"))
                .navigationDestination(for: SettingDestination.self) { destination in
                    switch destination {
                    case .memberAgreement:
                        TermsView(term: .membershipAgreement)
                    case .rentalAgreement:
                        TermsView(term: .rentalAgreement)
                    case .privacyPolicy:
                        TermsView(term: .privacyPolicy)
                    case .termsOfUse:
                        TermsView(term: .termsOfUse)
                    case .submitVehicleSnapshot:
                        AdminVehicleSubmissionView()
                    case .deleteAccount:
                        DeleteAccountView()
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
        } else {
            EmptyView()
        }
    }
    
    @ApiCallActor func logoutRequestAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                let request = veygoCurlRequest(url: "/api/v1/user/token", method: .delete, headers: ["auth": "\(token)$\(userId)"])
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

private struct DeleteAccountView: View {
    @EnvironmentObject private var session: UserSession
    
    @State private var acknowledgements = Array(repeating: false, count: DeleteAccountAcknowledgement.items.count)
    @State private var isSubmitting = false
    
    private var allAcknowledged: Bool {
        acknowledgements.allSatisfy { $0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Please review and confirm each statement below before submitting your account deletion request.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textBlackSecondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(DeleteAccountAcknowledgement.items.enumerated()), id: \.offset) { index, item in
                        acknowledgementRow(item.text, isChecked: acknowledgements[index]) {
                            acknowledgements[index].toggle()
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color("CardBG"))
                )
                
                Button {
                    Task {
                        isSubmitting = true
                        await ApiCallActor.shared.appendApi { token, userId in
                            await deleteAccountRequestAsync(token, userId)
                        }
                        await MainActor.run {
                            isSubmitting = false
                        }
                    }
                } label: {
                    Text(isSubmitting ? "Submitting..." : "Request Account Deletion")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .tint(Color("InvalidRed"))
                .buttonStyle(.glassProminent)
                .disabled(!allAcknowledged || isSubmitting)
            }
            .padding(20)
        }
        .background(Color("MainBG").ignoresSafeArea())
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.large)
    }
    
    @ViewBuilder
    private func acknowledgementRow(_ text: String, isChecked: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isChecked ? Color("AccentColor") : Color.textBlackSecondary)
                    .padding(.top, 1)
                
                Text(text)
                    .font(.body)
                    .foregroundStyle(Color.textBlackPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    @ApiCallActor
    private func deleteAccountRequestAsync(_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { session.user }
            if !token.isEmpty && userId > 0, user != nil {
                let request = veygoCurlRequest(
                    url: "/api/v1/user",
                    method: .delete,
                    headers: ["auth": "\(token)$\(userId)"]
                )
                let (_, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    return .doNothing
                }
                
                switch httpResponse.statusCode {
                case 200, 401:
                    await MainActor.run {
                        session.user = nil
                    }
                    return .clearUser
                default:
                    return .doNothing
                }
            }
            return .doNothing
        } catch {
            return .doNothing
        }
    }
}

private enum DeleteAccountAcknowledgement {
    static let items: [AcknowledgementItem] = [
        .init(text: "I understand my account must be in good standing before this request can be processed."),
        .init(text: "I confirm that I do not have any upcoming reservations."),
        .init(text: "I confirm that I do not have any active reservations."),
        .init(text: "I understand it may take up to 28 days to process this request."),
        .init(text: "I understand Veygo may contact me within those 28 days to resolve any outstanding balance."),
        .init(text: "I understand that using the service after submitting this request will automatically cancel it."),
        .init(text: "I understand that deleting my account does not remove my name from the do-not-rent list."),
        .init(text: "I understand Veygo will email me with updates on my request and let me know if any additional information is needed."),
        .init(text: "I understand that I will be automatically logged out after submitting this request."),
        .init(text: "I understand that account deletion is permanent and cannot be reversed."),
        .init(text: "I understand that Veygo will delete the personal data associated with my account in accordance with its policies and legal obligations.")
    ]
    
    struct AcknowledgementItem {
        let text: String
    }
}
