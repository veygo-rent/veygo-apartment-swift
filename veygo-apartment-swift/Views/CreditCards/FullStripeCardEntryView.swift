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
    
    @EnvironmentObject var session: UserSession
    
    @FocusState private var focusedField: Field?
    
    @State private var isSubmitting: Bool = false
    
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
            (self.cardholderName, self.nickname)
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
            if !token.isEmpty && userId > 0, user != nil {
                
                await MainActor.run {
                    isSubmitting = true
                }
                
                let payment = try await STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams)
                
                let body = [
                    "pm_id": payment.stripeId,
                    "cardholder_name": enteredCardholderName,
                    "nickname": enteredNickname.isEmpty ? nil : enteredNickname
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
                
                await MainActor.run {
                    isSubmitting = false
                }
                
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
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ThreeDSRedirectResponse.self, from: data),
                          let url = URL(string: decodedBody.url) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid 3DS response"
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        threeDSRedirect = ThreeDSRedirect(url: url)
                    }
                    return .doNothing
                case 201:
                    let _ = await MainActor.run {
                        dismiss()
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
                    return .doNothing
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
                    return .doNothing
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
                    return .doNothing
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
            }
            return .doNothing
        } catch {
            await MainActor.run {
                isSubmitting = false
                alertTitle = "Internal Error"
                alertMessage = "\(error.localizedDescription)"
                showAlert = true
            }
            return .doNothing
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
