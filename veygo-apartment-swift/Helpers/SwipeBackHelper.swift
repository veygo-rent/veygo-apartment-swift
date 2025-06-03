//
//  SwipeBackHelper.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/3/25.
//
import SwiftUI

/// 在 NavigationStack 中启用左滑返回手势的 Helper
struct EnableSwipeBackGesture: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear

        DispatchQueue.main.async {
            if let navigationController = controller.navigationController {
                navigationController.interactivePopGestureRecognizer?.delegate = context.coordinator
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}

