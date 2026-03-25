//
//  AccountView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 3/24/26.
//

import SwiftUI

enum AccountDestination: Hashable, Sendable {
    // Account
    case profile
    case wallet
    case addCard
    case phone
    case email
    case submitFile
}

struct AccountView: View {
    
    @EnvironmentObject var session: UserSession
    
    @State private var cards: [PublishPaymentMethod] = []
    @State private var rewardHours: RewardHoursSummaryResponse? = nil
    @State private var isLoadingRewardHours: Bool = false
    
    @Binding var path: [AccountDestination]
    
    var body: some View {
        if let user = session.user {
            NavigationStack (path: $path) {
                List {
                    Section {
                        membershipSummaryCard
                            .listRowBackground(Color("CardBG"))
                            .listRowSeparator(.hidden)
                    }
                    .listSectionSeparator(.hidden)
                    
                    Section {
                        NavigationLink("Wallet", value: AccountDestination.wallet)
                        if !user.phoneIsVerified {
                            NavigationLink("Verify Phone Number", value: AccountDestination.phone)
                        }
                        
                        if !user.emailIsValid() {
                            NavigationLink("Verify Your Email", value: AccountDestination.email)
                        }
                        
                        NavigationLink("Submit Documents", value: AccountDestination.submitFile)
                    }
                    .listRowBackground(Color("CardBG"))
                    .foregroundStyle(Color("TextBlackSecondary"))
                    .listSectionSeparator(.hidden)
                }
                .scrollIndicators(.hidden)
                .scrollContentBackground(.hidden)
                .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
                .navigationTitle(Text("Account"))
                .onAppear {
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await loadRewardHoursAsync(token, userId)
                        }
                    }
                }
                .navigationDestination(for: AccountDestination.self) { dest in
                    switch dest {
                    case .profile:
                        Text("Profile")
                            .navigationTitle("Profile")
                    case .wallet:
                        CreditCardView(cards: $cards) {
                            path.append(.addCard)
                        }
                    case .addCard:
                        FullStripeCardEntryView()
                    case .phone:
                        PhoneVerifyView()
                    case .email:
                        EmailVerifyView()
                    case .submitFile:
                        SubmitFileView()
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var membershipSummaryCard: some View {
        let usedValue = NSDecimalNumber(decimal: rewardHours?.used.value ?? Decimal.zero).doubleValue
        let totalValue = NSDecimalNumber(decimal: rewardHours?.total.value ?? Decimal.zero).doubleValue
        let displayedTotal = max(totalValue, usedValue)
        
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                CircularProgressRing(
                    value: totalValue <= 0 ? 0 : usedValue,
                    total: totalValue <= 0 ? 1 : totalValue
                )
                
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Reward Hours")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", displayedTotal))
                            .font(.title3.weight(.semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Used")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f", usedValue))
                            .font(.title3.weight(.semibold))
                    }
                }
                
                Spacer(minLength: 0)
            }
            
            HStack(spacing: 10) {
                membershipStatChip(title: "Remaining", value: String(format: "%.2f", max(displayedTotal - usedValue, 0)))
                membershipStatChip(
                    title: "Usage",
                    value: "\(Int((totalValue > 0 ? min(max(usedValue / totalValue, 0), 1) : 0) * 100))%"
                )
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            if rewardHours == nil && isLoadingRewardHours {
                LoadingView()
                    .cornerRadius(24)
            }
        }
    }
    
    @ViewBuilder
    private func membershipStatChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textBlackPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.textBlackSecondary.opacity(0.05))
        )
    }
    
    @ApiCallActor
    private func loadRewardHoursAsync(_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                await MainActor.run {
                    isLoadingRewardHours = true
                }
                
                let request = veygoCurlRequest(
                    url: "/api/v1/user/reward-hour",
                    method: .get,
                    headers: ["auth": "\(token)$\(userId)"]
                )
                let (data, response) = try await URLSession.shared.data(for: request)
                
                await MainActor.run {
                    isLoadingRewardHours = false
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    return .doNothing
                }
                
                switch httpResponse.statusCode {
                case 200:
                    guard let decoded = try? VeygoJsonStandard.shared.decoder.decode(RewardHoursSummaryResponse.self, from: data) else {
                        return .doNothing
                    }
                    await MainActor.run {
                        rewardHours = decoded
                    }
                    return .doNothing
                case 401:
                    return .clearUser
                default:
                    return .doNothing
                }
            }
            return .doNothing
        } catch {
            await MainActor.run {
                isLoadingRewardHours = false
            }
            return .doNothing
        }
    }
}
