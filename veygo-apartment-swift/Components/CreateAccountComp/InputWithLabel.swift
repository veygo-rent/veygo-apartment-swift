//
//  InputWithLabel.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/19/25.
//

import SwiftUI

struct InputWithLabel: View {
    var label: String
    var placeholder: String
    @Binding var text: String
    var description1: String
    var description2: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.custom("SF Pro", size: 18).weight(.bold))
                .foregroundColor(.black)

            TextInputField(placeholder: placeholder, text: $text)

            Text(description1)
                .font(.custom("SF Pro", size: 12))
                .foregroundColor(.black)

            Text(description2)
                .font(.custom("SF Pro", size: 12))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    InputWithLabel(
        label: "Your Full Legal Name",
        placeholder: "John Appleseed",
        text: .constant(""),
        description1: "You must enter your full name",
        description2: "Your name must match the name appears on your official documents"
    )
}
