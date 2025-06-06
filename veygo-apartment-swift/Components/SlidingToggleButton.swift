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
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("TextFieldBg"))
                    .stroke(Color("TextFieldFrame"), lineWidth: 2)
                    .frame(maxWidth: .infinity, maxHeight: 34)
                
                // 蓝色滑块
                HStack {
                    if selectedOption == "Apartment" {
                        Spacer()
                    }
                    
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color("PrimaryButtonBg"))
                        .frame(width: geometry.size.width / 2, height: 30).padding(.horizontal, 1)
                    
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
            .frame(height: 31)
        }
        .frame(height: 31)
    }
}

#Preview {
    StatefulPreviewWrapper("University") { selected in
        SlidingToggleButton(selectedOption: selected)
    }
}

