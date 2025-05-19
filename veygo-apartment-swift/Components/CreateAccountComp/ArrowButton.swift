//
//  ArrowButton.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/19/25.
//

import SwiftUI

struct ArrowButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
                Circle()
                    .fill(Color("Primary1"))
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 2, y: 2)

                Image(systemName: "arrow.right")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(.top, 20)
    }
}

#Preview {
    ArrowButton {
        print("Arrow Pressed")
    }
}
