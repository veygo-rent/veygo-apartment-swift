//
//  ForgotPasswordButton.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/19/25.
//

import SwiftUI

struct ForgotPasswordButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text("Forgot Password?")
                .font(.custom("SF Pro", size: 14))
                .foregroundColor(Color("HighLightText"))
                .underline()
        }
        .padding(.top, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 50) // 左侧对齐
    }
}

#Preview {
    ForgotPasswordButton {
        print("Forgot Password Pressed")
    }
}

