//
//  LargeTitleText.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/19/25.
//

import SwiftUI

struct LargeTitleText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 38, weight: .semibold, design: .default))
            .foregroundColor(Color("TextBlackPrimary"))
            .multilineTextAlignment(.center)
    }
}

#Preview {
    LargeTitleText(text: "Welcome!\nWhat's Your Name")
}
