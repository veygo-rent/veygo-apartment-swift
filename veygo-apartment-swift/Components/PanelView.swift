//
//  PanelView.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/5/25.
//

import SwiftUI

struct PanelView: View {
    var reservationNumber: String
    var dateTime: String
    var location: String
    var locationNote: String
    
    var modifyAction: () -> Void
    var cancelAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 上半部分
            VStack(alignment: .leading, spacing: 0) {
                Text("Reservation Number: \(reservationNumber)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color("TextBlackPrimary"))
                    .padding(.leading, -20)
                    .padding(.bottom, 13)
                
                Text(dateTime)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color("TextBlackSecondary"))
                    .padding(.leading, -20)
                    .padding(.bottom, 5)
                
                Text(location)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color("TextBlackSecondary"))
                    .padding(.leading, -20)
                    .padding(.bottom, 5)
                
                Text(locationNote)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color("TextBlackSecondary"))
                    .padding(.leading, -20)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            
            Divider()
                .frame(height: 1)
            
            // 下半部分
            HStack {
                Spacer()
                Button("Modify", action: modifyAction)
                    .foregroundColor(Color("SecondaryButtonText"))
                    .frame(maxWidth: .infinity)
                    .padding(.trailing, 16)
                Spacer()
                
                Spacer()
                Button("Cancel", action: cancelAction)
                    .foregroundColor(Color("SecondaryButtonText"))
                    .frame(maxWidth: .infinity)
                    .padding(.leading, 16)
                Spacer()
            }
            .frame(height: 40)
            .padding(.horizontal, 20)
        }
        .background(Color("CardBG"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("TextFieldFrame"), lineWidth: 1)
        )
    }
}

#Preview {
    PanelView(
        reservationNumber: "PU28367359",
        dateTime: "Jun 17 at 12:00 PM",
        location: "Purdue University Main Campus",
        locationNote: "(Exact location will be provided 30 minutes\nbefore rental starts)",
        modifyAction: { print("Modify tapped") },
        cancelAction: { print("Cancel tapped") }
    )
}
