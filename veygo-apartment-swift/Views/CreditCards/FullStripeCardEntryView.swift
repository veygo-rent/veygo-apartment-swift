//
//  FullStripeCardEntryView.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/2/25.
//
//

import SwiftUI
@preconcurrency import Stripe
import StripePaymentsUI
import StripeApplePay
import PassKit
import WebKit

struct FullStripeCardEntryView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @State private var paymentMethodParams: STPPaymentMethodParams? = nil
    @State private var cardholderName: String = ""
    @State private var nickname: String = ""
    @State private var showCardScan = false
    @State private var threeDSRedirect: ThreeDSRedirect?
    @State private var isApplePayAvailable: Bool = StripeAPI.deviceSupportsApplePay()
    @State private var applePayContext: STPApplePayContext?
    @State private var applePayDelegate = ApplePayDelegateProxy()
    
    @EnvironmentObject var session: UserSession
    
    @FocusState private var focusedField: Field?
    
    @State private var isSubmitting: Bool = false
    private let applePayMerchantIdentifier = "merchant.com.veygo-rent.veygo-apartment-swift"
    private let applePayCountryCode = "US"
    private let applePayCurrencyCode = "USD"
    private let applePayCompleteWithoutConfirmingIntent = "COMPLETE_WITHOUT_CONFIRMING_INTENT"
    
    enum Field: Hashable {
        case card
        case cardholder
        case nickname
    }

    var body: some View {
        VStack(spacing: 28) {
            
            CardInputFieldWrapper(paymentMethodParams: $paymentMethodParams)
                .background(Color("TextFieldBg"))
                .cornerRadius(14)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14))
                .frame(height: 36)
                .focused($focusedField, equals: .card)

            TextInputField(placeholder: "Cardholder", text: $cardholderName)
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
            
            TextInputField(placeholder: "Nickname (optional)", text: $nickname)
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
                Task {
                    await ApiCallActor.shared.appendApi { token, userId in
                        await createPaymentMethodAsync(token, userId)
                    }
                }
            }
            .disabled(paymentMethodParams == nil || !NameValidator(name: cardholderName).isValidName || isSubmitting)
        }
        .padding()
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("MainBG").ignoresSafeArea(.all))
        .navigationTitle("Add Card")
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if clearUserTriggered {
                    session.user = nil
                }
            }
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
    
    @ApiCallActor func createPaymentMethodAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        guard let params = await paymentMethodParams,
              let cardParams = params.card else { return .doNothing }

        let (enteredCardholderName, enteredNickname) = await MainActor.run {
            (
                self.cardholderName.trimmingCharacters(in: .whitespacesAndNewlines),
                self.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        
        let billingDetails = params.billingDetails ?? STPPaymentMethodBillingDetails()
        if !enteredCardholderName.isEmpty {
            billingDetails.name = enteredCardholderName
        }

        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: billingDetails,
            metadata: nil
        )
        do {
            let user = await MainActor.run { self.session.user }
            guard !token.isEmpty && userId > 0, user != nil else {
                return .doNothing
            }

            await MainActor.run {
                isSubmitting = true
            }
            defer {
                Task { @MainActor in
                    isSubmitting = false
                }
            }
            
            let payment = try await STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams)
            let (apiTaskResponse, _) = await submitPaymentMethodToBackendAsync(
                token,
                userId,
                paymentMethodId: payment.stripeId,
                cardholderName: enteredCardholderName,
                nickname: enteredNickname.isEmpty ? nil : enteredNickname
            )
            return apiTaskResponse
        } catch {
            await MainActor.run {
                alertTitle = "Internal Error"
                alertMessage = "\(error.localizedDescription)"
                showAlert = true
            }
            return .doNothing
        }
    }
    
    private func handleApplePayButtonTapped() {
        focusedField = nil

        let enteredCardholderName = cardholderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let enteredNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let paymentRequest = makeApplePayRequest()

        applePayDelegate.didCreatePaymentMethod = { paymentMethod, walletDisplayName, billingContactName, shippingContactName in
            await MainActor.run {
                isSubmitting = true
            }
            defer {
                Task { @MainActor in
                    isSubmitting = false
                }
            }
            
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
            let token = UserDefaults.standard.string(forKey: "token") ?? ""
            let userId = UserDefaults.standard.integer(forKey: "user_id")
            let (apiTaskResponse, succeeded) = await submitPaymentMethodToBackendAsync(
                token,
                userId,
                paymentMethodId: paymentMethod.stripeId,
                cardholderName: resolvedCardholderName,
                nickname: resolvedNickname
            )
            
            if case .clearUser = apiTaskResponse {
                await ApiCallActor.shared.appendApi { _, _ in
                    .clearUser
                }
            }
            
            guard succeeded else {
                throw NSError(
                    domain: "veygo.applepay",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to save Apple Pay payment method."]
                )
            }
            
            return applePayCompleteWithoutConfirmingIntent
        }
        applePayDelegate.didComplete = { status, error in
            applePayContext = nil
            switch status {
            case .error:
                if !showAlert {
                    alertTitle = "Apple Pay Error"
                    alertMessage = error?.localizedDescription ?? "Unable to complete Apple Pay."
                    showAlert = true
                }
            case .success, .userCancellation:
                break
            @unknown default:
                if !showAlert {
                    alertTitle = "Apple Pay Error"
                    alertMessage = "Unable to complete Apple Pay."
                    showAlert = true
                }
            }
        }
        
        guard let context = STPApplePayContext(paymentRequest: paymentRequest, delegate: applePayDelegate) else {
            alertTitle = "Apple Pay Unavailable"
            alertMessage = "Please verify Apple Pay is configured on this device and try again."
            showAlert = true
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
            if !formatted.isEmpty {
                return formatted
            }
        }
        if let shippingContactName {
            let formatted = shippingContactName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !formatted.isEmpty {
                return formatted
            }
        }
        
        return ""
    }
    
    private func submitPaymentMethodToBackendAsync(
        _ token: String,
        _ userId: Int,
        paymentMethodId: String,
        cardholderName: String,
        nickname: String?
    ) async -> (ApiTaskResponse, Bool) {
        do {
            let user = await MainActor.run { self.session.user }
            guard !token.isEmpty && userId > 0, user != nil else {
                return (.doNothing, false)
            }
            
            let body: [String: String?] = [
                "pm_id": paymentMethodId,
                "cardholder_name": cardholderName,
                "nickname": nickname
            ]
            
            let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(body)
            let request = veygoCurlRequest(
                url: "/api/v1/payment-method/create",
                method: .post,
                headers: [
                    "auth": "\(token)$\(userId)",
                ],
                body: jsonData
            )
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    alertTitle = "Server Error"
                    alertMessage = "Invalid protocol"
                    showAlert = true
                }
                return (.doNothing, false)
            }
            
            guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                await MainActor.run {
                    alertTitle = "Server Error"
                    alertMessage = "Invalid content"
                    showAlert = true
                }
                return (.doNothing, false)
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ThreeDSRedirectResponse.self, from: data),
                      let url = URL(string: decodedBody.url) else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid 3DS response"
                        showAlert = true
                    }
                    return (.doNothing, false)
                }
                await MainActor.run {
                    threeDSRedirect = ThreeDSRedirect(url: url)
                }
                return (.doNothing, true)
            case 201:
                await MainActor.run {
                    dismiss()
                }
                return (.doNothing, true)
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
                return (.clearUser, false)
            case 402:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E402
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                }
                return (.doNothing, false)
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
                return (.doNothing, false)
            case 406:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E406
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                }
                return (.doNothing, false)
            case 500:
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E406
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                }
                return (.doNothing, false)
            default:
                let body = ErrorResponse.E_DEFAULT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
                return (.doNothing, false)
            }
        } catch {
            await MainActor.run {
                alertTitle = "Internal Error"
                alertMessage = "\(error.localizedDescription)"
                showAlert = true
            }
            return (.doNothing, false)
        }
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
        let button = PKPaymentButton(paymentButtonType: .setUp, paymentButtonStyle: .black)
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
        // Styling to match SwiftUI modifiers
        textField.textColor = UIColor(named: "TextFieldWordColor") ?? .label
        textField.backgroundColor = UIColor(named: "TextFieldBg")

        // Corner radius
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
