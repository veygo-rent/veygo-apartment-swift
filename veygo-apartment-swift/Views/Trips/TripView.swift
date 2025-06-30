//
//  Plans.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/18/25.
//
import SwiftUI

public struct TripView: View {
    public var body: some View {
        VStack (alignment: .leading, spacing: 16) {
            
            // Upcoming Trip
            Title(text: "Upcoming Trip", fontSize: 20, color: Color("TextBlackPrimary"))
            PanelView(
                reservationNumber: "PU28367359",
                dateTime: "Jun 17 at 12:00 PM",
                location: "Purdue University Main Campus",
                locationNote: "(Exact location will be provided 30 minutes\nbefore rental starts)",
                modifyAction: { print("Modify tapped") },
                cancelAction: { print("Cancel tapped") }
            )
            
            Spacer()
            
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    TripView()
}

