//
//  NameView.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/19/25.
//

import SwiftUI

struct NameView: View {
    @State private var fullName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()

            // Title
            LargeTitleText(text: "Welcome!\nWhat’s Your Name")
                .padding(.bottom, 70)
                .frame(maxWidth: .infinity, alignment: .center)

            // Input + Description
            InputWithLabel(
                label: "Your Full Legal Name",
                placeholder: "John Appleseed",
                text: $fullName,
                description1: fullName.isEmpty ? "" : "You must enter your full name",
                description2: fullName.isEmpty ? "" : "Your name must match the name appears on your official documents"
            )
            .padding(.horizontal, 32)

            Spacer()

            // Arrow Button
            ArrowButton(isDisabled: !(fullName.contains(" ") && !fullName.isEmpty)) {
                print("Arrow pressed")
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 50)
        }
        .padding(.top, 40)
        .background(Color.white)
        .ignoresSafeArea()
    }
}

#Preview {
    NameView()
}
