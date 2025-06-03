import SwiftUI
import StripeCardScan

struct CardScanView: UIViewControllerRepresentable {
    var onResult: (CardScanSheetResult) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        return HostingController(onResult: onResult)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    class HostingController: UIViewController {
        let onResult: (CardScanSheetResult) -> Void

        init(onResult: @escaping (CardScanSheetResult) -> Void) {
            self.onResult = onResult
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)

            let cardScanSheet = CardScanSheet()
            cardScanSheet.present(from: self) { [weak self] result in
                self?.onResult(result)
            }
        }
    }
}
