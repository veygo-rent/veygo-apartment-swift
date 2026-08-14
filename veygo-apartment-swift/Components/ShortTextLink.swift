//
//  ShortTextLink.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/19/25.
//

import SwiftUI

struct ShortTextLink: View {
    let text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .font(.footnote)
                .fontWeight(.regular)
                .foregroundColor(Color.textLink)
                .underline()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
