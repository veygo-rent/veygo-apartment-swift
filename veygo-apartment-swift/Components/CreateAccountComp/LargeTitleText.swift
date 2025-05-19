//
//  LargeTitleText.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/19/25.
//

import SwiftUI

struct LargeTitleText: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.custom("SF Pro", size: 32).weight(.bold))
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .padding(.vertical, 10)
    }
}

#Preview {
    LargeTitleText(text: "Welcome!\nWhat's Your Name")
}
