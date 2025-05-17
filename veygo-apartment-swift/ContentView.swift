//
//  ContentView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 5/13/25.
// push test

import SwiftUI
import Stripe

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
                .onTapGesture {

                    let cardParams = STPPaymentMethodCardParams()
                    cardParams.number = "4242424242424242"
                    cardParams.expMonth = NSNumber(value: 10)
                    cardParams.expYear = NSNumber(value: 2028)
                    cardParams.cvc = "374"

                    let billingDetails = STPPaymentMethodBillingDetails()
                    billingDetails.name = "John Appleseed"

                    let paymentMethodParams = STPPaymentMethodParams(
                        card: cardParams,
                        billingDetails: billingDetails,
                        metadata: nil
                    )

                    STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
                        if let error = error {
                            print("Error creating payment method: \(error.localizedDescription)")
                        } else if let paymentMethod = paymentMethod {
                            print("Payment method created: \(paymentMethod.stripeId)")
                            // Send this paymentMethod ID to your backend
                        }
                    }


                }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
