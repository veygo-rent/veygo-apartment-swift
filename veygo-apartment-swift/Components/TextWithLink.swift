//
//  LegalText.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/19/25.
//

import SwiftUI

struct TextWithLink: View {
    var fullText: String
    var highlightedTexts: [(String, String)]

    var body: some View {
        Text(makeAttributedString())
            .font(.system(size: 11, weight: .regular, design: .default))
            .foregroundColor(Color("FootNote"))
    }

    private func makeAttributedString() -> AttributedString {
        var fullString = AttributedString(fullText)

        for (highlightedText, link) in highlightedTexts {
            if let range = fullString.range(of: highlightedText) {
                fullString[range].foregroundColor = Color("TextLink")
                fullString[range].underlineStyle = .single
                fullString[range].link = URL(string: link)!
            }
        }

        return fullString
    }
}
