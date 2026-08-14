//
//  SecondaryButtonLg.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/11/26.
//

import SwiftUI

struct SecondaryButtonLg: View {
    let text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .font(.title2)
                .fontWeight(.regular)
                .foregroundColor(Color.secondaryButtonText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .tint(Color.secondaryButtonBg)
        .frame(height: 53)
    }
}
