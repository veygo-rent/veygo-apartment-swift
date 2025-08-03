//
//  TimeSummary.swift
//  veygo-apartment-swift
//
//  Created by sardine on 8/2/25.
//

import SwiftUI

struct TimeSummary: View {
    let pickupTimeText: String
    let dropoffTimeText: String
    let onChangeTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Your pickup time:")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color("TextBlackPrimary"))

                Spacer()

                Button(action: onChangeTapped) {
                    Text("Change")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color("TextLink"))
                        .underline()
                }
            }

            Text(pickupTimeText)
                .font(.system(size: 17))
                .foregroundColor(Color("FootNote"))

            Text("Your drop off time:")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color("TextBlackPrimary"))

            Text(dropoffTimeText)
                .font(.system(size: 17))
                .foregroundColor(Color("FootNote"))
        }
        .padding()
    }
}

#Preview {
    TimeSummary(
        pickupTimeText: "Tue, Dec 12 @ 09:00 AM",
        dropoffTimeText: "Thu, Dec 15 @ 11:30 AM",
        onChangeTapped: {
            print("Change button tapped")
        }
    )
}
