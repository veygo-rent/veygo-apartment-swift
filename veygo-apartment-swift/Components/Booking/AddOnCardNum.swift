//
//  AddOnCardNum.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/9/25.
//

import SwiftUI

struct AddOnCardNum: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var pricePerDay: String
    @Binding var count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color("TextBlackPrimary"))
                    .padding(.leading, 10)
                    .padding(.vertical,5)

                Text(description)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color("FootNote"))
                    .padding(.leading, 10)
            }

            HStack {
                Text(pricePerDay)
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundColor(Color("TextBlackPrimary"))
                    .padding(.leading, 10)
                    .padding(.vertical, 4)

                Spacer()

                QuantityStepper(count: $count)
                    .frame(width: 141)
                    .padding(.trailing, 8)
            }
        }
        .background(
            Color("MainBG")
                .clipShape(
                    RoundedRectangle(cornerRadius: 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("TextFieldFrame").opacity(0.17), lineWidth: 1)
                )
        )
        .frame(width: 371, height: 152)
    }
}

#Preview {
    @Previewable @State var count = 0
    return AddOnCardNum(
        title: .constant("Additional Driver"),
        description: .constant("Add a friend (eligible license / age) to share driving. Same coverage applies."),
        pricePerDay: .constant("$19.98/day"),
        count: $count
    )
}

