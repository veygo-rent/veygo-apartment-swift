//
//  FullStripeCardEntryView.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/2/25.
//  Just a draft for now.
//

import SwiftUI
import Stripe
import StripePaymentsUI

struct FullStripeCardEntryView: View {
    @State private var paymentMethodParams: STPPaymentMethodParams? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Card Info")
                .font(.title)
                .padding()

            // Stripe 提供的卡片输入UI
            CardInputFieldWrapper(paymentMethodParams: $paymentMethodParams)
                .frame(height: 50)

            Button("Confirm") {
                guard let params = paymentMethodParams else { return }
                // TODO: Call API to create PaymentMethod with `params`
                print("Final PaymentMethodParams: \(params)")
            }
            .disabled(paymentMethodParams == nil)
            .padding()
        }
        .padding()
    }
}

// MARK: - CardInputFieldWrapper: UIViewRepresentable
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
