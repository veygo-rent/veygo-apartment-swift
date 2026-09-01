//
//  HistoryView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/1/26.
//

import SwiftUI

struct HistoryView: View {
    @Environment(Session.self) private var session

    @State private var pastAgreements: [Agreement]? = nil

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    var body: some View {
        List {
            if let pastAgreements {
                if pastAgreements.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No past rentals yet")
                            .font(.headline)
                            .foregroundStyle(Color.textBlackPrimary)
                        Text("Completed trips and receipts will show here.")
                            .font(.subheadline)
                            .foregroundStyle(Color.textBlackSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBG)
                    .cornerRadius(12)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.mainBG)
                } else {
                    ForEach(pastAgreements) { agreement in
                        agreementCard(for: agreement)
                    }
                }
            } else {
                ForEach(0..<3, id: \.self) { _ in
                    agreementCard(for: nil)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .navigationTitle(Text("Past Rentals"))
        .scrollContentBackground(.hidden)
        .background(Color.mainBG, ignoresSafeAreaEdges: .all)
        .task {
            await loadPastRentals()
        }
        .refreshable {
            await loadPastRentals()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    @ViewBuilder
    func agreementCard(for agreement: Agreement?) -> some View {
        let pickupTime = agreement?.actualPickupTime ?? agreement?.rsvpPickupTime
        let dropOffTime = agreement?.actualDropOffTime ?? agreement?.rsvpDropOffTime
        let statusText: String = {
            guard let agreement else { return "Rental" }
            if agreement.actualPickupTime == nil {
                return "No Show"
            }
            if agreement.status == .rental, agreement.actualDropOffTime != nil {
                return "Completed"
            }
            return agreement.status.rawValue
        }()

        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("RSVP")
                    .fontWeight(.bold)
                    .foregroundStyle(agreement == nil ? Color.clear : Color.textBlackPrimary)
                Text("#\(agreement?.confirmation ?? "ABCD-1234")")
                    .fontWeight(.semibold)
                    .foregroundStyle(agreement == nil ? Color.clear : Color.textLink)
            }
            Text("Pickup: \(pickupTime.map { VeygoDatetimeStandard.shared.formattedDateTime($0) } ?? "Mar 20, 9:00 AM")")
                .font(.callout)
                .foregroundStyle(agreement == nil ? Color.clear : Color.textBlackSecondary)
            Text("Dropoff: \(dropOffTime.map { VeygoDatetimeStandard.shared.formattedDateTime($0) } ?? "Mar 21, 9:00 AM")")
                .font(.callout)
                .foregroundStyle(agreement == nil ? Color.clear : Color.textBlackSecondary)
            HStack {
                Text("Status")
                    .font(.caption)
                    .foregroundStyle(agreement == nil ? Color.clear : Color.textBlackSecondary)
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(agreement == nil ? Color.clear : Color.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(agreement == nil ? Color.clear : Color.accentColor.opacity(0.35), lineWidth: 1)
                    }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBG)
        .cornerRadius(12)
        .overlay {
            if agreement == nil {
                LoadingView()
                    .cornerRadius(12)
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)
    }

    // MARK: - Load past rentals

    private func loadPastRentals() async {
        do {
            let agreements = try await fetchPastRentals()
            pastAgreements = agreements
        } catch let error as VeygoError {
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func fetchPastRentals() async throws -> [Agreement] {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unknown
        }

        let request = veygoCurlRequest(
            url: "/api/v1/agreement/past",
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
                return try VeygoJsonStandard.shared.decoder.decode([Agreement].self, from: data)
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

    // MARK: - Alert

    private func present(_ error: ErrorResponse) {
        present(title: error.title, message: error.message)
    }

    private func present(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
