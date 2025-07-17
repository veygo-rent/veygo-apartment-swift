//
//  TimeBanner.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/2/25.
//
import SwiftUI

struct TimeBanner: View {
    var startDate: Date
    var endDate: Date
    var onChange: () -> Void

    var body: some View {
        ZStack {
            Color("AccentColor")
            VStack {
                Spacer()
                HStack {
                    Text("\(formatted(startDate)) - \(formatted(endDate))")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color("TextFieldWordColor"))
                        .lineLimit(1)
                        

                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.bottom, 12)
            }
//            VStack {
//                HStack {
//                    Spacer()
//                    ShortTextLink(text: "Change", action: onChange)
//                        .padding(.trailing, 16)
//                        .padding(.bottom, 12)
//                }
//            }
        }
        .frame(height: 115)
        .frame(maxWidth: .infinity)
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h a"
        return formatter.string(from: date)
    }
}
#Preview {
    TimeBanner(startDate: Date(), endDate: Date(), onChange: { })
}
