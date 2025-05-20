//
//  LegalText.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/19/25.
//

import SwiftUI

struct LegalText: View {
    var body: some View {
        Text(makeAttributedString())
            .font(.system(size: 11, weight: .regular, design: .default)) // 使用 SF Pro 字体
            .foregroundColor(Color("Terms"))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func makeAttributedString() -> AttributedString {
        var fullString = AttributedString("By continuing, you acknowledge and agree to Veygo’s legal terms, which we recommend reviewing")
        
        if let range = fullString.range(of: "legal terms") {
            fullString[range].foregroundColor = Color("HighLightText")
            fullString[range].underlineStyle = .single
        }

        return fullString
    }
}

#Preview {
    LegalText()
}
