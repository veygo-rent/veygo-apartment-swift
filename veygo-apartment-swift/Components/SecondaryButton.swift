//
//  CreateButton.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//

import SwiftUI

struct SecondaryButton: View {
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
        .frame(height: 45)
    }
}

#Preview {
    SecondaryButton(text: "Create New Account") {
        print("Create Button Pressed")
    }
}



