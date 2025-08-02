//
//  BackButtonHiddenModifier.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 6/13/25.
//
// Conditional for iOS 26

import SwiftUI

struct BackButtonHiddenModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
        } else {
            content
                .navigationBarBackButtonHidden(true)
        }
    }
}

struct SwipeBackGestureModifier: ViewModifier {
    var action: () -> Void

    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 100 {
                            action()
                        }
                    }
            )
    }
}

extension View {
    func swipeBackGesture(action: @escaping () -> Void) -> some View {
        self.modifier(SwipeBackGestureModifier(action: action))
    }
}
