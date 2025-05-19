//
//  CreateButton.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//

import SwiftUI

struct SecondaryButtonLg: View {
    // 接收按钮文本和点击事件
    var text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .font(.system(size: 17, weight: .semibold, design: .default)) // SF Pro 字体
                .foregroundColor(Color("LoginPageButton1BG")) // 使用自定义颜色
                .frame(width: 338, height: 45)
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 1) // 黑色细边框
                )
        }
    }
}

#Preview {
    SecondaryButtonLg(text: "Create New Account") {
        print("Create Button Pressed")
    }
}



