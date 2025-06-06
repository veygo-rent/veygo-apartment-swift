//
//  InputWithInlinePrompt.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/5/25.
//
//
//  InputWithInlinePrompt.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/5/25.
//

import SwiftUI

struct InputWithInlinePrompt: View {
    let promptText: String
    @Binding var userInput: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Frame"), lineWidth: 1)
                .frame(width: 238, height: 53)
                .background(Color("MainBG"))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(promptText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("Terms"))
                    .padding(.leading, 10)
                
                TextField("", text: $userInput)
                    .font(.system(size: 14))
                    .foregroundColor(Color("TextFieldWordColor"))
                    .padding(.leading, 10)
            }
            .padding(.top, 6)
        }
    }
}

#Preview {
    StatefulPreviewWrapper("") { text in
        InputWithInlinePrompt(
            promptText: "Promo code / coupon",
            userInput: text
        )
    }
}
