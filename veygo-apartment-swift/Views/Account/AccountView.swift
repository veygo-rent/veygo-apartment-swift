//
//  AccountView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/13/26.
//

import SwiftUI

struct AccountView: View {
    @Environment(Session.self) private var session
    @Environment(Router.self) private var router

    @State private var rewardHours: RewardHoursSummaryResponse? = nil
    @State private var isLoadingRewardHours: Bool = false

    var body: some View {
        // Tab root — no NavigationStack; AppView owns the outer stack and
        // registers AccountDestination destinations.
        Group {
            if let user = session.renter {
                accountList(user: user)
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func accountList(user: PublishRenter) -> some View {
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
        .task {
            await loadRewardHours()
        }
    }

    // MARK: - Membership card

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

    // MARK: - Load reward hours

    private func loadRewardHours() async {
        do {
            let summary = try await fetchRewardHours()
            rewardHours = summary
        } catch let error as VeygoError {
            if case .unauthorized = error {
                session.clear()
            }
            // Reward-hours failure is non-fatal for the screen; no alert.
        } catch {
            // ignore
        }
    }

    private func fetchRewardHours() async throws -> RewardHoursSummaryResponse {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unknown
        }

        isLoadingRewardHours = true
        defer { isLoadingRewardHours = false }

        let request = veygoCurlRequest(
            url: "/api/v1/user/reward-hour",
            method: .get,
            headers: ["auth": "\(token)$\(userId)"]
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return try VeygoJsonStandard.shared.decoder.decode(RewardHoursSummaryResponse.self, from: data)
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.unauthorized(decodedError)
            } else {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.server(status: httpCode, error: decodedError)
            }
        } catch let error as URLError {
            throw VeygoError.network(error)
        } catch _ as DecodingError {
            throw VeygoError.decoding
        } catch let error as VeygoError {
            throw error
        } catch {
            throw VeygoError.unknown
        }
    }
}
