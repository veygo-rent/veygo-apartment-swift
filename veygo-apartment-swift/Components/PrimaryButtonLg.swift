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

struct PrimaryButtonLg: View {
    // 接收按钮文本和点击事件
    var text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .font(.system(size: 17, weight: .semibold, design: .default)) // 使用 SF Pro 字体
                .foregroundColor(Color("LoginPageButtonText")) // 使用 Assets 中的颜色
                .frame(width: 338, height: 45)
                .background(Color("LoginPageButton1BG"))
                .cornerRadius(16)
                .shadow(color: Color("LoginPageButton1BG").opacity(0.7), radius: 3, x: 2, y: 4)
        }
    }
}

#Preview {
    PrimaryButtonLg(text: "Login") {
        print("Log In Button Pressed")
    }
}
