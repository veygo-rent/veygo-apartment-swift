//
//  TermsView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 11/28/25.
//

import SwiftUI

struct TermsView: View {
    enum TermType: String {
        case privacyPolicy = "Privacy Policy"
        case membershipAgreement = "Member Agreement"
        case rentalAgreement = "Rental Agreement"
        case termsOfUse = "Terms of Use"
    }
    
    @Environment(\.dismiss) var dismiss
    @State private var termWording: AttributedString? = nil
    
    @State private var showAlert: Bool = false
    @State private var toDismiss: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    
    let term: TermType
    var body: some View {
        List {
            if let termWording = termWording {
                Text(termWording)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color("MainBG"))
            } else {
                Text("Loading \(term.rawValue)")
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color("MainBG"))
            }
        }
        .frame(maxWidth: .infinity)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.never)
        .listStyle(.plain)
        .background(Color("MainBG").ignoresSafeArea(.all))
        .navigationTitle(term.rawValue)
        .navigationBarTitleDisplayMode(.automatic)
        .onAppear {
            if term != .termsOfUse {
                Task {
                    await ApiCallActor.shared.appendApi { _, _ in
                        await fetchPilicyAsync()
                    }
                }
            }
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
    
    @ApiCallActor func fetchPilicyAsync() async -> ApiTaskResponse {
        let policyType: String
        switch term {
        case .privacyPolicy:
            policyType = "privacy"
        case .membershipAgreement:
            policyType = "membership"
        case .rentalAgreement:
            policyType = "rental"
        case .termsOfUse:
            policyType = "terms_of_use"
        }
        
        let request = veygoCurlRequest(
            url: "/api/v1/policy?type=\(policyType)",
            method: .get
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    alertTitle = "Server Error"
                    alertMessage = "Invalid protocol"
                    showAlert = true
                }
                return .doNothing
            }
            
            guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                await MainActor.run {
                    alertTitle = "Server Error"
                    alertMessage = "Invalid content"
                    showAlert = true
                }
                return .doNothing
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(Policy.self, from: data) else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                await MainActor.run {
                    termWording = try! AttributedString(markdown: decodedBody.content, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
                }
                return .doNothing
            case 404:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                        toDismiss = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E404
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                        toDismiss = true
                    }
                }
                return .doNothing
            case 500:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                        toDismiss = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E500
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                        toDismiss = true
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
