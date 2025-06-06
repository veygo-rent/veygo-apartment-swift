//
//  SlidingToggleButton.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/6/25.
//

import SwiftUI

struct SlidingToggleButton: View {
    @Binding var selectedOption: String
    
    private let options = ["University", "Apartment"]
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("TextBlackSecondary").opacity(0.3), lineWidth: 2)
                .background(
                    Color("MainBG").cornerRadius(16)
                )
                .frame(maxWidth: .infinity, maxHeight: 31)
            
            // 蓝色滑块
            HStack {
                if selectedOption == "Apartment" {
                    Spacer()
                }
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("PrimaryButtonBg"))
                    .frame(width: 147, height: 31)
                
                if selectedOption == "University" {
                    Spacer()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedOption)
            
            // 文本按钮
            HStack(spacing: 0) {
                Button("University") {
                    selectedOption = "University"
                }
                .foregroundColor(selectedOption == "University" ? Color("PrimaryButtonText") : Color("TextBlackSecondary"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Button("Apartment") {
                    selectedOption = "Apartment"
                }
                .foregroundColor(selectedOption == "Apartment" ? Color("PrimaryButtonText") : Color("TextBlackSecondary"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 299, height: 31)
    }
}

#Preview {
    StatefulPreviewWrapper("University") { selected in
        SlidingToggleButton(selectedOption: selected)
    }
}

