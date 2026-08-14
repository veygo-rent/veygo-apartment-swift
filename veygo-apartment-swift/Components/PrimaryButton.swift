//
//  PrimaryButton.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/11/26.
//

import SwiftUI

struct PrimaryButton: View {
    let text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .font(.title3)
                .fontWeight(.regular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .tint(Color.primaryButtonBg)
        .frame(height: 45)
    }
}
