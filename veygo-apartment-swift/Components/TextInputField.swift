//
//  TextInputField.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/12/26.
//

import SwiftUI

struct TextInputField: View {
    @Binding var text: String
    
    let placeholder: String
    var isSecure: Bool = false
    var textFont: Font = .callout
    
    private let cornerRadius: CGFloat = 16
    
    var body: some View {
        if isSecure {
            SecureField(placeholder, text: $text)
                .font(textFont)
                .kerning(2)
                .padding(.vertical, 10)
                .foregroundColor(Color.textFieldWord)
                .padding(.leading, 16)
                .background(Color.textFieldBg)
                .cornerRadius(cornerRadius)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
        } else {
            TextField(placeholder, text: $text)
                .font(textFont)
                .kerning(1.5)
                .padding(.vertical, 10)
                .foregroundColor(Color.textFieldWord)
                .padding(.leading, 16)
                .background(Color.textFieldBg)
                .cornerRadius(cornerRadius)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
        }
    }
}
