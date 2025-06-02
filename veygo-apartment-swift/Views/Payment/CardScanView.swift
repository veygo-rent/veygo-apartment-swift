//
//  CardScanView.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/2/25.
//  Draft for now

import SwiftUI
import StripePaymentSheet

struct CardScanView: View {
    @State private var paymentSheet: PaymentSheet? = nil
    @State private var isPaymentSheetReady = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Your Card").font(.title)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Scan & Save Card") {
                presentPaymentSheet()
            }
            .disabled(!isPaymentSheetReady)
            .padding()
            .background(isPaymentSheetReady ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .onAppear {
            // 用本地假数据配置 PaymentSheet
            loadFakeSetupIntent()
        }
    }
    
    /// 用本地假数据，跳过后端 API
    private func loadFakeSetupIntent() {
        let fakeClientSecret = "seti_1234567890_fake_secret_for_demo"
        configurePaymentSheet(with: fakeClientSecret)
    }
    
    /// 配置 Stripe PaymentSheet
    private func configurePaymentSheet(with setupIntentClientSecret: String) {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Veygo"
        // 这里的 returnURL 只是个示例
        configuration.returnURL = "yourapp://stripe-redirect"

        self.paymentSheet = PaymentSheet(
            setupIntentClientSecret: setupIntentClientSecret,
            configuration: configuration
        )
        self.isPaymentSheetReady = true
        print("PaymentSheet configured with fake SetupIntent")
    }
    
    /// 展示 PaymentSheet UI，让用户手动输入或拍照识别卡片
    private func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        
        paymentSheet.present(from: rootVC) { paymentResult in
            switch paymentResult {
            case .completed:
                print("Card saved successfully!")
                // TODO: 后面集成后端 API 逻辑
            case .canceled:
                print("User canceled")
            case .failed(let error):
                self.errorMessage = "Failed: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    CardScanView()
}
