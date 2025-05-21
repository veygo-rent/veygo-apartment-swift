//
//  ArrowButton.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/19/25.
//

import SwiftUI

struct ArrowButton: View {
    var isDisabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: {
            if !isDisabled {
                action()
            }
        }) {
            ZStack {
                Circle()
                    .fill(isDisabled ? Color("Terms") : Color("AccentColor"))
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: isDisabled ? .clear : Color.black.opacity(0.25),
                        radius: 4, x: 0, y: 4
                    )

                Image(systemName: "arrow.right")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(Color("MainBG"))
            }
        }
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        ArrowButton {
            print("Enabled")
        }
        ArrowButton(isDisabled: true) {
            print("Disabled")
        }
    }
}
