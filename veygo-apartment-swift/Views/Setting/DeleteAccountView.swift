//
//  DeleteAccountView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/25/26.
//

import SwiftUI

struct DeleteAccountView: View {
    @Environment(Session.self) private var session

    @State private var acknowledgements = Array(repeating: false, count: Acknowledgement.items.count)
    @State private var isSubmitting = false

    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

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
                    ForEach(Array(Acknowledgement.items.enumerated()), id: \.offset) { index, item in
                        acknowledgementRow(item.text, isChecked: acknowledgements[index]) {
                            acknowledgements[index].toggle()
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.cardBG)
                )

                Button {
                    Task { await deleteAccount() }
                } label: {
                    Text(isSubmitting ? "Submitting..." : "Request Account Deletion")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .tint(Color.invalidRed)
                .buttonStyle(.glassProminent)
                .disabled(!allAcknowledged || isSubmitting)
            }
            .padding(20)
        }
        .background(Color.mainBG.ignoresSafeArea())
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.large)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    @ViewBuilder
    private func acknowledgementRow(_ text: String, isChecked: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isChecked ? Color.accentColor : Color.textBlackSecondary)
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

    // MARK: - Delete

    private func deleteAccount() async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await deleteAccountRequest()
            session.clear()   // success → logged out; RootView drops to login
        } catch let error as VeygoError {
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func deleteAccountRequest() async throws {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unknown
        }

        let request = veygoCurlRequest(
            url: "/api/v1/user",
            method: .delete,
            headers: ["auth": "\(token)$\(userId)"]
        )
        do {
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            // 200 = deleted, 401 = token already invalid — both mean logged out.
            if httpCode == 200 || httpCode == 401 {
                return
            } else {
                throw VeygoError.server(status: httpCode, error: .E_DEFAULT)
            }
        } catch let error as URLError {
            throw VeygoError.network(error)
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

    // MARK: - Acknowledgements

    private enum Acknowledgement {
        struct Item {
            let text: String
        }

        static let items: [Item] = [
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
    }
}
