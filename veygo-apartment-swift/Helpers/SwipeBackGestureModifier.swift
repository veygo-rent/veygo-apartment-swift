//
//  SwipeBackGestureModifier.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/3/25.
//

import SwiftUI

/// 一个可复用的 ViewModifier，封装自定义左滑返回手势
struct SwipeBackGestureModifier: ViewModifier {
    /// 触发“返回”逻辑的回调
    var action: () -> Void

    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 100 {
                            // 检测到右滑，触发回调
                            action()
                        }
                    }
            )
    }
}

extension View {
    /// 给任意视图添加左滑返回手势
    func swipeBackGesture(action: @escaping () -> Void) -> some View {
        self.modifier(SwipeBackGestureModifier(action: action))
    }
}
