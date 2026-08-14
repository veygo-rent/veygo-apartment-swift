//
//  InputWithInlinePrompt.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/12/26.
//

import SwiftUI

struct InputWithInlinePrompt: View {
    @Binding var userInput: String
    
    let promptText: String
    
    private let cornerRadius: CGFloat = 16
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.textFieldBg)
                .stroke(Color.textFieldFrame, lineWidth: 1)
                .frame(height: 53)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(promptText)
                    .font(.caption)
                    .foregroundColor(Color.footNote)
                
                TextField("", text: $userInput)
                    .font(.callout)
                    .foregroundColor(Color.textFieldWord)
                    .frame(height: 24, alignment: .leading)
            }
            .padding(.leading, 16)
            .padding(.top, 6)
        }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
    }
}
