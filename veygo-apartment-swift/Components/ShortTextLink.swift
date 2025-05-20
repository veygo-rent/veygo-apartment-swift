//
//  ForgotPasswordButton.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/19/25.
//

import SwiftUI

struct ShortTextLink: View {
    var text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .font(.custom("SF Pro", size: 14))
                .foregroundColor(Color("HighLightText"))
                .underline()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ShortTextLink(text: "Forgot Password?") {
        print("Forgot Password Pressed")
    }
}

