//
//  CreateButton.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//

import SwiftUI

struct SecondaryButton: View {
    // 接收按钮文本和点击事件
    let text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .font(.system(size: 17, weight: .semibold, design: .default)) // SF Pro 字体
                .foregroundColor(Color("SecondaryButtonText")) // 使用自定义颜色
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(Color("SecondaryButtonBg"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("SecondaryButtonOutline"), lineWidth: 1) // 黑色细边框
                )
        }
    }
}

#Preview {
    SecondaryButton(text: "Create New Account") {
        print("Create Button Pressed")
    }
}



