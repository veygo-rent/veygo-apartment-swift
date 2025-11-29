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
import StripeCardScan

struct FullStripeCardEntryView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @State private var paymentMethodParams: STPPaymentMethodParams? = nil
    @State private var cardholderName: String = ""
    @State private var nickname: String = ""
    @State private var showCardScan = false
    
    @EnvironmentObject var session: UserSession
    
    @Binding var path: [SettingDestination]

    var body: some View {
        VStack(spacing: 28) {
            
            CardInputFieldWrapper(paymentMethodParams: $paymentMethodParams)
                .background(Color("TextFieldBg"))
                .cornerRadius(14)
                .frame(height: 36)

            TextInputField(placeholder: "Cardholder", text: $cardholderName)
            
            TextInputField(placeholder: "Nickname (optional)", text: $nickname)
            
            Spacer()
            
            
            PrimaryButton(text: "Confirm") {
                Task {
                    await ApiCallActor.shared.appendApi { token, userId in
                        await createPaymentMethodAsync(token, userId)
                    }
                }
            }
            .disabled(paymentMethodParams == nil || !NameValidator(name: cardholderName).isValidName)
        }
        .padding()
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("MainBG"), ignoresSafeAreaEdges: .all)
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
    }
    
    @ApiCallActor func createPaymentMethodAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        guard let params = await paymentMethodParams,
              let cardParams = params.card else { return .doNothing }
        
        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: nil,
            metadata: nil
        )
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                let payment = try await STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams, additionalPaymentUserAgentValues: [])
                
                let body = await [
                    "pm_id": payment.stripeId,
                    "cardholder_name": cardholderName,
                    "nickname": nickname.isEmpty ? nil : nickname
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
                case 201:
                    nonisolated struct ResponseObject: Decodable {
                        let newPaymentMethod: PublishPaymentMethod
                    }
                    let token = extractToken(from: response, for: "Creating payment method") ?? ""
                    let _ = await MainActor.run {
                        path.removeLast()
                    }
                    return .renewSuccessful(token: token)
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
                alertTitle = "Internal Error"
                alertMessage = "\(error.localizedDescription)"
                showAlert = true
            }
            return .doNothing
        }
    }

}

// MARK: - CardInputFieldWrapper
struct CardInputFieldWrapper: UIViewRepresentable {
    @Binding var paymentMethodParams: STPPaymentMethodParams?

    func makeUIView(context: Context) -> STPPaymentCardTextField {
        let textField = STPPaymentCardTextField()
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

    class Coordinator: NSObject, @preconcurrency STPPaymentCardTextFieldDelegate {
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
