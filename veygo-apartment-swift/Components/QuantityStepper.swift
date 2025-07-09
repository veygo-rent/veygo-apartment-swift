//
//  QuantityStepper.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/9/25.
//、
import SwiftUI

struct QuantityStepper: View {
    @Binding var count: Int

    var body: some View {
        HStack(spacing: 24) {
            Button(action: {
                if count > 0 {
                    count -= 1
                }
            }) {
                Image(systemName: "minus.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(count == 0 ? Color("FootNote") : Color("TextBlackPrimary"))
            }
            .disabled(count == 0)

            Text("\(count)")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color("TextBlackPrimary"))

            Button(action: {
                count += 1
            }) {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color("TextBlackPrimary"))
            }
        }
        .frame(width: 144, height: 53)
    }
}

struct QuantityStepper_PreviewWrapper: View {
    @State private var count = 0

    var body: some View {
        QuantityStepper(count: $count)
            .padding()
    }
}

#Preview {
    QuantityStepper_PreviewWrapper()
}
