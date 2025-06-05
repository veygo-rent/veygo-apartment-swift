//
//  InputWithInlinePrompt.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/5/25.
//

import SwiftUI

struct InputWithInlinePrompt: View {
    @Binding var promptText: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Frame"), lineWidth: 1)
                .frame(width: 238, height: 53)
            
            Text(promptText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color("Terms"))
                .frame(width: 261.09, height: 10, alignment: .leading)
                .padding(.leading)
                .padding(.top, -15)
        }
    }
}

#Preview {
    StatefulPreviewWrapper("Promo code / coupon") { text in
        InputWithInlinePrompt(promptText: text)
    }
}
