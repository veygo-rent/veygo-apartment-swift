//
//  BackButton.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/20/25.
//
import SwiftUI

struct BackButton: View {
    var body: some View {
        Image(systemName: "arrow.left")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(Color("Black1"))
    }
}

#Preview {
    BackButton()
}

