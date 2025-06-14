//
//  SlidingToggleButton.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/6/25.
//

import SwiftUI

enum RentalOption: String, CaseIterable, Identifiable {
    case university, apartment
    var id: Self { self }
}

struct SlidingToggleButton: View {
    @Binding var selectedOption: RentalOption
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("TextFieldBg"))
                    .stroke(Color("TextFieldFrame"), lineWidth: 2)
                    .frame(maxWidth: .infinity, maxHeight: 42)
                
                // 蓝色滑块
                HStack {
                    if selectedOption == .apartment {
                        Spacer()
                    }
                    
                    RoundedRectangle(cornerRadius: 19)
                        .fill(Color("PrimaryButtonBg"))
                        .frame(width: geometry.size.width / 2, height: 38).padding(.horizontal, 2)
                    
                    if selectedOption == .university {
                        Spacer()
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: selectedOption)
                
                // 文本按钮
                HStack(spacing: 0) {
                    Button("University") {
                        selectedOption = .university
                    }
                    .foregroundColor(selectedOption == .university ? Color("PrimaryButtonText") : Color("SecondaryButtonText"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Button("Apartment") {
                        selectedOption = .apartment
                    }
                    .foregroundColor(selectedOption == .apartment ? Color("PrimaryButtonText") : Color("SecondaryButtonText"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 42)
        }
        .frame(height: 42)
    }
}

#Preview {
    StatefulPreviewWrapper(RentalOption.university) { selected in
        SlidingToggleButton(selectedOption: selected)
    }
}

