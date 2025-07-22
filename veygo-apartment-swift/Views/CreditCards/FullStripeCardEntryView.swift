//
//  FullStripeCardEntryView.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/2/25.
//
//

import SwiftUI
import Stripe
import StripePaymentsUI

struct FullStripeCardEntryView: View {
    @State private var paymentMethodParams: STPPaymentMethodParams? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var cardholderName: String = ""
    @State private var nickname: String = ""

    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Card Info")
                .font(.title)
                .padding()

            CardInputFieldWrapper(paymentMethodParams: $paymentMethodParams)
                .frame(height: 50)

            TextField("Cardholder Name", text: $cardholderName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("Nickname (optional)", text: $nickname)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            
            Button("Confirm") {
                createPaymentMethod()
            }
            .disabled(paymentMethodParams == nil || cardholderName.isEmpty)
            .padding()
        }
        .padding()
        .alert("Result", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    func createPaymentMethod() {
        guard let params = paymentMethodParams else { return }
        guard let cardParams = params.card else { return }

        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: nil,
            metadata: nil
        )

        STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
            if let error = error {
                alertMessage = "Stripe error: \(error.localizedDescription)"
                showAlert = true
                return
            }

            guard let paymentMethod = paymentMethod else {
                alertMessage = "Failed to create payment method."
                showAlert = true
                return
            }

            print("Created PaymentMethod: \(paymentMethod.stripeId)")
            sendTokenToBackend(pmId: paymentMethod.stripeId)
        }
    }

    func sendTokenToBackend(pmId: String) {
        let bodyDict: [String: Any] = [
            "pm_id": pmId,
            "cardholder_name": cardholderName,
            "nickname": nickname.isEmpty ? NSNull() : nickname
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: bodyDict) else {
            alertMessage = "Failed to encode request body"
            showAlert = true
            return
        }

        let request = veygoCurlRequest(
            url: "/api/v1/payment-method/create",
            method: "POST",
            headers: [
                "auth": "\(token)$\(userId)",
                "Content-Type": "application/json",
                "User-Agent": "iOS-App"
            ],
            body: body
        )

        print("URL: \(request.url?.absoluteString ?? "nil")")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "Backend error: \(error.localizedDescription)"
                    showAlert = true
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    alertMessage = "Invalid response from server"
                    showAlert = true
                    return
                }

                guard let data = data else {
                    alertMessage = "Empty response from server"
                    showAlert = true
                    return
                }

                if httpResponse.statusCode == 201 {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let newToken = json["token"] as? String {
                        self.token = newToken // 更新token
                        alertMessage = "Card added successfully!"
                    } else {
                        alertMessage = "Card added but failed to parse new token"
                    }
                } else {
                    let responseText = String(data: data, encoding: .utf8) ?? "Unknown error"
                    alertMessage = "Failed to add card: \(responseText)"
                }

                showAlert = true
            }
        }.resume()
    }

}

// MARK: - CardInputFieldWrapper
struct CardInputFieldWrapper: UIViewRepresentable {
    @Binding var paymentMethodParams: STPPaymentMethodParams?

    func makeUIView(context: Context) -> STPPaymentCardTextField {
        let textField = STPPaymentCardTextField()
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

        func paymentCardTextFieldDidChange(_ textField: STPPaymentCardTextField) {
            if textField.isValid {
                parent.paymentMethodParams = textField.paymentMethodParams
            } else {
                parent.paymentMethodParams = nil
            }
        }
    }
}

#Preview {
    FullStripeCardEntryView()
}
