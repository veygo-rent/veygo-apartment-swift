//
//  TextInputField.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//
import SwiftUI

struct TextInputField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("TextFieldBg"))
                .stroke(Color("TextFieldFrame"), lineWidth: 1) // 边框颜色
                .frame(height: 42)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .frame(height: 42)
                    .foregroundColor(Color("TextFieldWordColor"))
                    .padding(.leading, 16)
                    .kerning(2)
            } else {
                TextField(placeholder, text: $text)
                    .frame(height: 42)
                    .foregroundColor(Color("TextFieldWordColor"))
                    .padding(.leading, 16)
                    .kerning(1.5)
            }
        }
    }
}

#Preview {
    TextInputField(placeholder: "Email", text: .constant(""))
}
