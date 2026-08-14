//
//  TermsView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/13/26.
//

import SwiftUI

struct TermsView: View {
    enum TermType: String {
        case privacyPolicy = "Privacy Policy"
        case membershipAgreement = "Member Agreement"
        case rentalAgreement = "Rental Agreement"
        case termsOfUse = "Terms of Use"

        /// The `type` query value the policy endpoint expects.
        var apiValue: String {
            switch self {
            case .privacyPolicy:       return "privacy"
            case .membershipAgreement: return "membership"
            case .rentalAgreement:     return "rental"
            case .termsOfUse:          return "usage"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var termWording: AttributedString? = nil
    @State private var effectiveDate: Date? = nil

    @State private var showAlert: Bool = false
    @State private var toDismiss: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    let term: TermType

    var body: some View {
        List {
            if let termWording, let effectiveDate {
                HStack {
                    Text("Effective Date:")
                        .foregroundColor(Color.textBlackPrimary)
                        .font(.body.bold())
                    Text(VeygoDatetimeStandard.shared.mediumLengthDateString(from: effectiveDate))
                        .foregroundColor(Color.textBlackPrimary)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.mainBG)
                Text(termWording)
                    .foregroundColor(Color.textBlackPrimary)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.mainBG)
            } else {
                Text("Loading \(term.rawValue)")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color.textBlackPrimary)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.mainBG)
                    .overlay {
                        LoadingView().cornerRadius(12)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.never)
        .listStyle(.plain)
        .background(Color("MainBG").ignoresSafeArea(.all))
        .navigationTitle(term.rawValue)
        .navigationBarTitleDisplayMode(.automatic)
        .task {
            await loadPolicy()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if toDismiss {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    private func loadPolicy() async {
        do {
            let policy = try await fetchPolicy()

            guard let date = VeygoDatetimeStandard.shared.yyyyMMddDateFormatter.date(from: policy.policyEffectiveDate) else {
                present(title: "Server Error", message: "Invalid content")
                return
            }
            let wording = (try? AttributedString(
                markdown: policy.content,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            )) ?? AttributedString(policy.content)

            effectiveDate = date
            termWording = wording
        } catch let error as VeygoError {
            // 404 / 500 should bounce the user out of this screen.
            if case .server = error {
                present(error.display, dismissAfter: true)
            } else {
                present(error.display)
            }
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func fetchPolicy() async throws -> Policy {
        let request = veygoCurlRequest(
            url: "/api/v1/policy?type=\(term.apiValue)",
            method: .get
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                let decodedPolicy = try VeygoJsonStandard.shared.decoder.decode(Policy.self, from: data)
                return decodedPolicy
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

    private func present(_ error: ErrorResponse, dismissAfter: Bool = false) {
        present(title: error.title, message: error.message, dismissAfter: dismissAfter)
    }

    private func present(title: String, message: String, dismissAfter: Bool = false) {
        alertTitle = title
        alertMessage = message
        toDismiss = dismissAfter
        showAlert = true
    }
}
