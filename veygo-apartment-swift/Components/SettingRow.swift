//
//  SettingRow.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/4/25.
//

import SwiftUI

struct SettingsRow: View {
    let title: String
    let subtitle: String?
    let showSubtitle: Bool
    let showVerification: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: subtitle != nil && showSubtitle ? 2 : 0) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color("TextBlackPrimary"))

                    if let subtitle = subtitle, showSubtitle {
                        Text(subtitle)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color("TextBlackPrimary"))
                    }
                }

                Spacer()
                
                if showVerification {
                    Text("Needs Verification")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color("InvalidRed"))

                }
                Image(systemName: "chevron.right")
                    .resizable()
                    .frame(width: 7, height: 12)
                    .foregroundColor(Color("TextBlackPrimary"))
                    .padding(.trailing, 10)
            }

            Divider()
                .frame(height: 1)
                .padding(.leading, 0)
                .background(Color("SeparateLine"))
        }
    }
}

#Preview {
    SettingsRow(title: "Membership", subtitle: "Diamond Member", showSubtitle: true, showVerification: true)
}
