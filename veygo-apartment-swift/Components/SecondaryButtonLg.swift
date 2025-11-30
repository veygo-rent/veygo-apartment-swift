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
                .font(.system(size: 17, weight: .semibold, design: .default))
                .foregroundColor(Color("SecondaryButtonText"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .tint(Color("SecondaryButtonBg"))
        .frame(height: 53)
    }
}

#Preview {
    SecondaryButtonLg(text: "Apply") {
    }
}




