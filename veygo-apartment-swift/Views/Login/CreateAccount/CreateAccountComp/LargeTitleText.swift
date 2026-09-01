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
            .font(.largeTitle)
            .fontWeight(.semibold)
            .foregroundColor(Color.textBlackPrimary)
            .multilineTextAlignment(.center)
    }
}
