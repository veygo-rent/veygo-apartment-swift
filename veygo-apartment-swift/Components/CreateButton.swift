//
//  CreateButton.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//

import SwiftUI

struct CreateButton: View {
    // 接收按钮文本和点击事件
    var text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .font(.custom("SF Pro", size: 18).weight(.semibold)) // SF Pro 字体
                .foregroundColor(Color("LoginPageButton1BG")) // 使用自定义颜色
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.clear) // 透明背景
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 2) // 黑色细边框
                )
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 2, y: 2) // 阴影效果
        }
        .padding(.horizontal, 40) // 左右留白
    }
}

#Preview {
    CreateButton(text: "Create New Account") {
        print("Create Button Pressed")
    }
}



