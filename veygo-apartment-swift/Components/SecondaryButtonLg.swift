//
//  LargerSecondaryButtonLg.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/5/25.
//

import SwiftUI

struct SecondaryButtonLg: View {
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
                .frame(height: 53)
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
    SecondaryButtonLg(text: "Apply") {
    }
}




