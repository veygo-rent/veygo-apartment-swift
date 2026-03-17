//
//  MembershipView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 3/16/26.
//

import SwiftUI

struct CircularProgressRing: View {
    let value: Double
    let total: Double
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(max(value / total, 0), 1)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.footNote.opacity(0.15), lineWidth: 10)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.textBlackPrimary)
                Text("used")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 104, height: 104)
    }
}

struct MembershipView: View {
    
    @EnvironmentObject var session: UserSession
    @Environment(\.dismiss) private var dismiss
    
    @State private var rewardHours: RewardHoursSummaryResponse? = nil
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    @State private var dismissTriggered: Bool = false
    
    var body: some View {
        if let _ = session.user {
            ScrollView {
                if let rewardHours = rewardHours {
                    let usedValue = NSDecimalNumber(decimal: rewardHours.used.value).doubleValue
                    let totalValue = NSDecimalNumber(decimal: rewardHours.total.value).doubleValue
                    let displayedTotal = max(totalValue, usedValue)
                    
                    VStack(spacing: 20) {
                        HStack(alignment: .center, spacing: 18) {
                            CircularProgressRing(
                                value: totalValue <= 0 ? 0 : usedValue,
                                total: totalValue <= 0 ? 1 : totalValue
                            )
                            
                            VStack(alignment: .leading, spacing: 12) {
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
                        
                        HStack(spacing: 12) {
                            statChip(title: "Remaining", value: String(format: "%.2f", max(displayedTotal - usedValue, 0)))
                            statChip(title: "Usage", value: "\(Int((totalValue > 0 ? min(max(usedValue / totalValue, 0), 1) : 0) * 100))%")
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.cardBG)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                } else {
                    VStack(spacing: 20) {
                        HStack(alignment: .center, spacing: 18) {
                            CircularProgressRing(
                                value: 0,
                                total: 1
                            )
                            
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Reward Hours")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%.2f", 0.00))
                                        .font(.title3.weight(.semibold))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Used")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%.2f", 0.00))
                                        .font(.title3.weight(.semibold))
                                }
                            }
                            
                            Spacer(minLength: 0)
                        }
                        
                        HStack(spacing: 12) {
                            statChip(title: "Remaining", value: String(format: "%.2f", 0.00))
                            statChip(title: "Usage", value: "0.00%")
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    )
                    .overlay(
                        LoadingView()
                            .cornerRadius(24)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.mainBG)
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.large)
            .navigationTitle(Text("Membership Detail"))
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") {
                    if clearUserTriggered {
                        session.user = nil
                    }
                    if dismissTriggered {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                Task {
                    await ApiCallActor.shared.appendApi { token, userId in
                        await checkPromoAsync(token, userId)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func statChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    @ApiCallActor func checkPromoAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            
            if !token.isEmpty && userId > 0, user != nil {
                
                let request = veygoCurlRequest(url: "/api/v1/user/reward-hour", method: .get, headers: ["auth": "\(token)$\(userId)"])
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid protocol"
                        showAlert = true
                        dismissTriggered = true
                    }
                    return .doNothing
                }
                switch httpResponse.statusCode {
                case 200:
                    let rewardHoursDecoded: RewardHoursSummaryResponse = try! VeygoJsonStandard.shared.decoder.decode(RewardHoursSummaryResponse.self, from: data)
                    await MainActor.run {
                        rewardHours = rewardHoursDecoded
                    }
                    return .doNothing
                case 401:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E401
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    }
                    return .clearUser
                case 405:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            dismissTriggered = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E405
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            dismissTriggered = true
                        }
                    }
                    return .doNothing
                default:
                    let body = ErrorResponse.E_DEFAULT
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                        dismissTriggered = true
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
                dismissTriggered = true
            }
            return .doNothing
        }
    }
}
