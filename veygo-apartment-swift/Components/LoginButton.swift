//
//  LoginButton.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//

//
//  LoginButton.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//

import SwiftUI

struct LoginButton: View {
    // 接收按钮文本和点击事件
    var text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .font(.custom("SF Pro", size: 18).weight(.semibold)) // 使用 SF Pro 字体
                .foregroundColor(Color("LoginPageButtonText")) // 使用 Assets 中的颜色
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color("LoginPageButton1BG"))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 2, y: 2)
        }
        .padding(.horizontal, 40) // 左右留白
    }
}

#Preview {
    LoginButton(text: "Login") {
        print("Log In Button Pressed")
    }
}
