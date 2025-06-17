//
//  LargerPrimaryButtonLg.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/5/25.
//
import SwiftUI

struct LargerPrimaryButtonLg: View {
    let text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .font(.system(size: 17, weight: .semibold, design: .default)) // 使用 SF Pro 字体
                .foregroundColor(Color("PrimaryButtonText"))
                .frame(maxWidth: .infinity)
                .frame(height: 53)
                .background(Color("PrimaryButtonBg"))
                .cornerRadius(16)
                .shadow(color: Color("ShadowPrimary").opacity(0.5), radius: 3, x: 2, y: 4)
        }
    }
}

#Preview {
    LargerPrimaryButtonLg(text: "Vehicle Look Up") {
    }
}

