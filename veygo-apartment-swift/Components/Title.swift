//
//  Title.swift - size and color changeable
//  veygo-apartment-swift
//
//  Created by Sardine on 6/6/25.
//

import SwiftUI

struct Title: View {
    var text: String
    var fontSize: CGFloat
    var color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .semibold))
    }
}

#Preview {
    Title(text: "Welcome to Veygo", fontSize: 24, color: Color("TextBlackPrimary"))
}
