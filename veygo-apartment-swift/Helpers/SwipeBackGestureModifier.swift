//
//  SwipeBackGestureModifier.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/3/25.
//

import SwiftUI

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
