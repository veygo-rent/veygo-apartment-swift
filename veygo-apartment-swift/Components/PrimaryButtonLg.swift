//
//  LargerPrimaryButtonLg.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/5/25.
//
import SwiftUI

struct PrimaryButtonLg: View {
    let text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .font(.system(size: 17, weight: .semibold, design: .default))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .tint(Color("PrimaryButtonBg"))
        .frame(height: 53)
    }
}

#Preview {
    PrimaryButtonLg(text: "Vehicle Look Up") {
    }
}

