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
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color("TextFieldFrame"), lineWidth: 1) // 边框颜色
                .background(Color.white) // 背景透明
                .frame(maxWidth: .infinity)
                .frame(height: 42)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .frame(height: 42)
                    .foregroundColor(.black)
                    .padding(.leading, 16)
            } else {
                TextField(placeholder, text: $text)
                    .frame(height: 42)
                    .foregroundColor(.black)
                    .padding(.leading, 16)
            }
        }
    }
}

#Preview {
    TextInputField(placeholder: "Email", text: .constant(""))
}

