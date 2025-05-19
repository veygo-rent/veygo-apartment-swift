//
//  TextInputField.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//
import SwiftUI

struct TextInputField: View {
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        ZStack {
            // 背景透明
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color("TextFieldFrame"), lineWidth: 2) // 边框颜色
                .background(Color.clear) // 背景透明

            if isSecure {
                SecureField(placeholder, text: $text)
                    .padding()
                    .foregroundColor(.black)
            } else {
                TextField(placeholder, text: $text)
                    .padding()
                    .foregroundColor(.black)
            }
        }
        .frame(height: 50)  // 统一高度
        .padding(.horizontal, 40) // 左右留白
        .padding(.vertical, 8)    // 上下间距
    }
}

#Preview {
    TextInputField(placeholder: "Email", text: .constant(""))
}

