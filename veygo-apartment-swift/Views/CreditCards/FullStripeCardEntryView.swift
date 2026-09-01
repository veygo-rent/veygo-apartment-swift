//
//  FullStripeCardEntryView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/1/26.
//

import SwiftUI
@preconcurrency import Stripe
import StripePaymentsUI
import PassKit
import WebKit

struct FullStripeCardEntryView: View {
    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    @State private var paymentMethodParams: STPPaymentMethodParams? = nil
    @State private var cardholderName: String = ""
    @State private var nickname: String = ""
    @State private var showCardScan = false
    @State private var threeDSRedirect: ThreeDSRedirect?
    @State private var isApplePayAvailable: Bool = StripeAPI.deviceSupportsApplePay()
    @State private var applePayContext: STPApplePayContext?
    @State private var applePayDelegate = ApplePayDelegateProxy()

    @FocusState private var focusedField: Field?

    @State private var isSubmitting: Bool = false
    @State private var applePayServerError: ErrorResponse? = nil
    private let applePayMerchantIdentifier = "merchant.com.veygo-rent.veygo-apartment-swift"
    private let applePayCountryCode = "US"
    private let applePayCurrencyCode = "USD"
    private let applePayCompleteWithoutConfirmingIntent = "COMPLETE_WITHOUT_CONFIRMING_INTENT"

    enum Field: Hashable {
        case card
        case cardholder
        case nickname
    }

    /// Outcome of a backend payment-method submission.
    private enum SubmitOutcome {
        case needsThreeDS(URL)   // 200 — must present 3DS
        case created             // 201 — saved directly
    }

    var body: some View {
        VStack(spacing: 28) {

            CardInputFieldWrapper(paymentMethodParams: $paymentMethodParams)
                .background(Color("TextFieldBg"))
                .cornerRadius(14)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))
                .frame(height: 36)
                .focused($focusedField, equals: .card)

            TextInputField(text: $cardholderName, placeholder: "Cardholder")
                .focused($focusedField, equals: .cardholder)
                .textInputAutocapitalization(.words)
                .onChange(of: focusedField) { oldValue, _ in
                    if oldValue == .cardholder {
                        let filtered = cardholderName.filter { $0.isLetter || $0.isWhitespace }
                        let formatted = filtered
                            .split(separator: " ")
                            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
                            .joined(separator: " ")
                        cardholderName = formatted
                    }
                }

            TextInputField(text: $nickname, placeholder: "Nickname (optional)")
                .focused($focusedField, equals: .nickname)

            Spacer()

            if isApplePayAvailable {
                ApplePayButtonRepresentable(action: handleApplePayButtonTapped)
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
                    .cornerRadius(14)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))
                    .disabled(isSubmitting)
            }

            PrimaryButton(text: "Confirm") {
                focusedField = nil
                Task { await confirmCard() }
            }
            .disabled(paymentMethodParams == nil || !NameValidator(name: cardholderName).isValidName || isSubmitting)
        }
        .padding()
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("MainBG").ignoresSafeArea(.all))
        .navigationTitle("Add Card")
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onTapGesture {
            focusedField = nil
        }
        .onAppear {
            isApplePayAvailable = StripeAPI.deviceSupportsApplePay()
        }
        .sheet(item: $threeDSRedirect) { redirect in
            ThreeDSWebViewSheet(
                redirectURL: redirect.url,
                onThreeDSCompleted: {
                    threeDSRedirect = nil
                    dismiss()
                }
            )
        }
    }

    // MARK: - Manual card confirm

    private func confirmCard() async {
        guard let params = paymentMethodParams, let cardParams = params.card else { return }

        let enteredCardholderName = cardholderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let enteredNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)

        let billingDetails = params.billingDetails ?? STPPaymentMethodBillingDetails()
        if !enteredCardholderName.isEmpty {
            billingDetails.name = enteredCardholderName
        }

        let methodParams = STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let payment = try await STPAPIClient.shared.createPaymentMethod(with: methodParams)
            let outcome = try await submitPaymentMethod(
                paymentMethodId: payment.stripeId,
                cardholderName: enteredCardholderName,
                nickname: enteredNickname.isEmpty ? nil : enteredNickname
            )
            switch outcome {
            case .needsThreeDS(let url):
                threeDSRedirect = ThreeDSRedirect(url: url)
            case .created:
                dismiss()
            }
        } catch let error as VeygoError {
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            present(title: "Internal Error", message: error.localizedDescription)
        }
    }

    // MARK: - Apple Pay

    private func handleApplePayButtonTapped() {
        focusedField = nil

        let enteredCardholderName = cardholderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let enteredNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let paymentRequest = makeApplePayRequest()

        applePayDelegate.didCreatePaymentMethod = { paymentMethod, walletDisplayName, billingContactName, shippingContactName in
            isSubmitting = true
            defer { isSubmitting = false }

            applePayServerError = nil   // reset for this attempt

            let resolvedCardholderName = resolvedCardholderName(
                enteredCardholderName: enteredCardholderName,
                paymentMethod: paymentMethod,
                billingContactName: billingContactName,
                shippingContactName: shippingContactName
            )
            let resolvedNickname = resolvedNickname(
                enteredNickname: enteredNickname,
                paymentMethod: paymentMethod,
                walletDisplayName: walletDisplayName
            )

            do {
                // Apple Pay path: a successful save either creates directly or
                // returns 3DS; either way we don't confirm an intent here.
                _ = try await submitPaymentMethod(
                    paymentMethodId: paymentMethod.stripeId,
                    cardholderName: resolvedCardholderName,
                    nickname: resolvedNickname
                )
                return applePayCompleteWithoutConfirmingIntent
            } catch let error as VeygoError {
                if case .unauthorized = error { session.clear() }
                applePayServerError = error.display   // remember the server's message
                throw NSError(
                    domain: "veygo.applepay",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: error.display.message]
                )
            }
        }
        applePayDelegate.didComplete = { status, error in
            applePayContext = nil
            switch status {
            case .error:
                if !showAlert {
                    // Prefer the server's ErrorResponse message if we captured one.
                    if let serverError = applePayServerError {
                        present(serverError)
                    } else {
                        present(title: "Apple Pay Error",
                                message: error?.localizedDescription ?? "Unable to complete Apple Pay.")
                    }
                }
                applePayServerError = nil
            case .success:
                dismiss()
            case .userCancellation:
                applePayServerError = nil
            @unknown default:
                if !showAlert {
                    present(title: "Apple Pay Error", message: "Unable to complete Apple Pay.")
                }
                applePayServerError = nil
            }
        }

        guard let context = STPApplePayContext(paymentRequest: paymentRequest, delegate: applePayDelegate) else {
            present(title: "Apple Pay Unavailable",
                    message: "Please verify Apple Pay is configured on this device and try again.")
            return
        }

        applePayContext = context
        context.presentApplePay()
    }

    private func makeApplePayRequest() -> PKPaymentRequest {
        let request = StripeAPI.paymentRequest(
            withMerchantIdentifier: applePayMerchantIdentifier,
            country: applePayCountryCode,
            currency: applePayCurrencyCode
        )
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Veygo (No charge today)", amount: .zero, type: .final)
        ]
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.merchantCategoryCode = .init(rawValue: 7512)
        return request
    }

    private func resolvedNickname(
        enteredNickname: String,
        paymentMethod: STPPaymentMethod,
        walletDisplayName: String?
    ) -> String? {
        if !enteredNickname.isEmpty {
            return enteredNickname
        }
        if let displayName = walletDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !displayName.isEmpty {
            return displayName
        }
        if let last4 = paymentMethod.card?.last4, !last4.isEmpty {
            return "Apple Pay •••• \(last4)"
        }
        return nil
    }

    private func resolvedCardholderName(
        enteredCardholderName: String,
        paymentMethod: STPPaymentMethod,
        billingContactName: String?,
        shippingContactName: String?
    ) -> String {
        if !enteredCardholderName.isEmpty {
            return enteredCardholderName
        }
        if let billingName = paymentMethod.billingDetails?.name?.trimmingCharacters(in: .whitespacesAndNewlines),
           !billingName.isEmpty {
            return billingName
        }
        if let billingContactName {
            let formatted = billingContactName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !formatted.isEmpty { return formatted }
        }
        if let shippingContactName {
            let formatted = shippingContactName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !formatted.isEmpty { return formatted }
        }
        return ""
    }

    // MARK: - Backend submit

    private func submitPaymentMethod(
        paymentMethodId: String,
        cardholderName: String,
        nickname: String?
    ) async throws -> SubmitOutcome {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unknown
        }

        let body: [String: String?] = [
            "pm_id": paymentMethodId,
            "cardholder_name": cardholderName,
            "nickname": nickname
        ]
        let jsonData = try VeygoJsonStandard.shared.encoder.encode(body)
        let request = veygoCurlRequest(
            url: "/api/v1/payment-method/create",
            method: .post,
            headers: ["auth": "\(token)$\(userId)"],
            body: jsonData
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            switch httpCode {
            case 200:
                let decoded = try VeygoJsonStandard.shared.decoder.decode(ThreeDSRedirectResponse.self, from: data)
                guard let url = URL(string: decoded.url) else {
                    throw VeygoError.decoding
                }
                return .needsThreeDS(url)
            case 201:
                return .created
            case 401:
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.unauthorized(decodedError)
            default:
                let decodedError = (try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)) ?? .E_DEFAULT
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

@MainActor
private final class ApplePayDelegateProxy: NSObject, STPApplePayContextDelegate {
    var didCreatePaymentMethod: (@MainActor (_ paymentMethod: STPPaymentMethod, _ walletDisplayName: String?, _ billingContactName: String?, _ shippingContactName: String?) async throws -> String)?
    var didComplete: (@MainActor (_ status: STPPaymentStatus, _ error: Error?) -> Void)?

    func applePayContext(
        _ context: STPApplePayContext,
        didCreatePaymentMethod paymentMethod: STPPaymentMethod,
        paymentInformation: PKPayment,
        completion: @escaping STPIntentClientSecretCompletionBlock
    ) {
        Task { @MainActor in
            do {
                guard let didCreatePaymentMethod else {
                    completion(
                        nil,
                        NSError(
                            domain: "veygo.applepay",
                            code: 2,
                            userInfo: [NSLocalizedDescriptionKey: "Apple Pay delegate not configured."]
                        )
                    )
                    return
                }

                let formatter = PersonNameComponentsFormatter()
                let billingContactName = paymentInformation.billingContact?.name.map { formatter.string(from: $0) }
                let shippingContactName = paymentInformation.shippingContact?.name.map { formatter.string(from: $0) }
                let walletDisplayName = paymentInformation.token.paymentMethod.displayName
                let clientSecret = try await didCreatePaymentMethod(
                    paymentMethod,
                    walletDisplayName,
                    billingContactName,
                    shippingContactName
                )
                completion(clientSecret, nil)
            } catch {
                completion(nil, error)
            }
        }
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didCompleteWith status: STPPaymentStatus,
        error: Error?
    ) {
        didComplete?(status, error)
    }
}

private struct ApplePayButtonRepresentable: UIViewRepresentable {
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: .setUp, paymentButtonStyle: .automatic)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        button.cornerRadius = 14
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}

    final class Coordinator: NSObject {
        let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func tapped() {
            action()
        }
    }
}

private struct ThreeDSRedirectResponse: Decodable {
    let url: String
}

private struct ThreeDSRedirect: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ThreeDSWebViewSheet: View {
    let redirectURL: URL
    let onThreeDSCompleted: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Stripe3DSWebView(redirectURL: redirectURL) {
                onThreeDSCompleted()
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Verify Card")
            .background(Color.mainBG.ignoresSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct Stripe3DSWebView: UIViewRepresentable {
    private static let threeDSReturnURLPrefix = "veygo-app://3ds-dismissed"

    let redirectURL: URL
    let onCompleted: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCompleted: onCompleted)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: redirectURL))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let onCompleted: () -> Void

        init(onCompleted: @escaping () -> Void) {
            self.onCompleted = onCompleted
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            if let currentURLString = navigationAction.request.url?.absoluteString,
               currentURLString.hasPrefix(Stripe3DSWebView.threeDSReturnURLPrefix) {
                onCompleted()
                return .cancel
            }
            return .allow
        }
    }
}

struct CardInputFieldWrapper: UIViewRepresentable {
    @Binding var paymentMethodParams: STPPaymentMethodParams?

    func makeUIView(context: Context) -> STPPaymentCardTextField {
        let textField = STPPaymentCardTextField()
        textField.postalCodeEntryEnabled = true
        textField.layer.borderWidth = 0
        textField.layer.borderColor = UIColor.clear.cgColor
        textField.textColor = UIColor(named: "TextFieldWordColor") ?? .label
        textField.backgroundColor = UIColor(named: "TextFieldBg")
        textField.layer.cornerRadius = 14
        textField.layer.masksToBounds = true
        textField.delegate = context.coordinator
        return textField
    }

    func updateUIView(_ uiView: STPPaymentCardTextField, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, STPPaymentCardTextFieldDelegate {
        var parent: CardInputFieldWrapper
        init(parent: CardInputFieldWrapper) { self.parent = parent }

        @MainActor func paymentCardTextFieldDidChange(_ textField: STPPaymentCardTextField) {
            if textField.isValid {
                parent.paymentMethodParams = textField.paymentMethodParams
            } else {
                parent.paymentMethodParams = nil
            }
        }
    }
}
