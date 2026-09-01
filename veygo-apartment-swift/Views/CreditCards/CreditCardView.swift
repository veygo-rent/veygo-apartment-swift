//
//  CreditCardView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/1/26.
//

import SwiftUI

struct CreditCardView: View {
    @Environment(Session.self) private var session
    @Environment(Router.self) private var router

    @State private var sensoryFeedbackTrigger: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    @State private var isLoading: Bool = false

    @State private var cards: [PublishPaymentMethod] = []
    @State private var expandedCardID: PublishPaymentMethod.ID? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassEffectContainer {
                List {
                    if !isLoading {
                        ForEach(cards) { card in
                            CreditCardRow(
                                card: card,
                                isExpanded: expandedCardID == card.id,
                                onTap: {
                                    sensoryFeedbackTrigger.toggle()
                                    withAnimation(.easeInOut) {
                                        expandedCardID = (expandedCardID == card.id) ? nil : card.id
                                    }
                                }
                            )
                            .listRowSeparator(.hidden, edges: .all)
                            .listRowBackground(Color.mainBG)
                        }
                        .onDelete { indexSet in
                            Task { await deleteCard(at: indexSet) }
                        }
                    } else {
                        LoadingView()
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                            .listRowSeparator(.hidden, edges: .all)
                            .listRowBackground(Color.mainBG)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await loadCards()
                }
            }

            Spacer()

            PrimaryButton(text: "Add Card") {
                router.push(AccountDestination.addCard)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationTitle(Text("My Cards"))
        .background(Color.mainBG, ignoresSafeAreaEdges: .all)
        .task {
            await loadCards()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sensoryFeedback(.selection, trigger: sensoryFeedbackTrigger)
    }

    // MARK: - Load cards

    private func loadCards() async {
        do {
            let loaded = try await fetchCards()
            cards = loaded
            isLoading = false
        } catch let error as VeygoError {
            isLoading = false
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            isLoading = false
            present(.E_DEFAULT)
        }
    }

    private func fetchCards() async throws -> [PublishPaymentMethod] {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unknown
        }

        isLoading = true
        let request = veygoCurlRequest(
            url: "/api/v1/payment-method/get",
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
                return try VeygoJsonStandard.shared.decoder.decode([PublishPaymentMethod].self, from: data)
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

    // MARK: - Delete card

    private func deleteCard(at offsets: IndexSet) async {
        guard !cards.isEmpty, let index = offsets.first else {
            present(title: "Internal Error", message: "Trying to delete a card that doesn't exist")
            return
        }
        let cardToDelete = cards[index]

        do {
            try await deleteCardRequest(cardId: cardToDelete.id)
            cards.remove(at: index)
        } catch let error as VeygoError {
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func deleteCardRequest(cardId: Int) async throws {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unknown
        }

        let request = veygoCurlRequest(
            url: "/api/v1/payment-method/delete/\(cardId)",
            method: .delete,
            headers: ["auth": "\(token)$\(userId)"]
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return
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

private struct CreditCardRow: View {

    private func convertDateToString(_ date: Date?) -> String {
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        } else {
            return "Never"
        }
    }

    let card: PublishPaymentMethod
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 16) {
                cardBrandImage(for: card.network)
                    .frame(width: 64, height: 64)
                    .cornerRadius(4)

                VStack(alignment: .leading, spacing: 2) {
                    Text(card.nickname ?? card.maskedCardNumber)
                        .font(.headline)
                        .foregroundStyle(Color.textBlackPrimary)
                    Text("Exp: \(card.expiration)")
                        .font(.subheadline)
                        .foregroundStyle(Color.footNote)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .onTapGesture {
                onTap()
            }

            if isExpanded {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Card Number:")
                            .font(.subheadline)
                            .foregroundStyle(Color.textBlackSecondary)
                        Text("\(card.maskedCardNumber)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textBlackSecondary)
                    }
                    HStack {
                        Text("Last Used:")
                            .font(.subheadline)
                            .foregroundStyle(Color.textBlackSecondary)
                        Text("\(convertDateToString(card.lastUsedDateTime))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textBlackSecondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBG, ignoresSafeAreaEdges: .all)
        .cornerRadius(12)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
    }
}

@ViewBuilder
func cardBrandImage(for brand: String) -> some View {
    let lowercased = brand.lowercased()
    let knownBrands = ["amex", "mastercard", "visa", "discover"]

    if knownBrands.contains(lowercased) {
        Image(lowercased)
            .resizable()
            .frame(width: 64, height: 42)
    } else {
        Image(systemName: "creditcard")
            .resizable()
            .frame(width: 32, height: 22)
            .foregroundColor(.primaryButtonBg)
    }
}
