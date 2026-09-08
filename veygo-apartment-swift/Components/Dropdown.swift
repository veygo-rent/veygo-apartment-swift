//
//  Dropdown.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/7/26.
//

import SwiftUI

struct Dropdown: View {
    
    @Binding var selectedOption: Apartment.ID?
    @Binding var labelText: String
    
    @Binding var universityOptions: [Apartment]
    
    @State private var showOptions = false
    
    var body: some View {
        VStack (spacing: 16) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.textFieldBg)
                    .stroke(Color.textFieldFrame, lineWidth: 1)
                    .frame(height: 53)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        // rental location
                        Text(labelText)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.footNote)
                            .frame(height: 10, alignment: .leading)
                        // University name
                        if let selectedOption = selectedOption {
                            if let univ = universityOptions.getItemBy(id: selectedOption) {
                                Text(univ.name)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.textFieldWord)
                                    .frame(height: 24, alignment: .leading)
                            }
                        }
                    }
                    .frame(height: 53)
                    .padding(.leading, 16)
                    Spacer()
                    // Dropdown Button
                    Button(action: {
                        withAnimation {
                            showOptions.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .resizable()
                            .frame(width: 15, height: 7)
                            .foregroundColor(Color.dropdown)
                            .font(.body)
                            .fontWeight(.bold)
                            .rotationEffect(.degrees(showOptions ? 180 : 0))
                            .animation(.easeInOut, value: showOptions)
                    }
                    .padding(.trailing, 16)
                }
                
            }
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
            
            if showOptions {
                let renderedOptions = universityOptions.indices.map { index in
                    VStack(spacing: 0) {
                        Button(action: {
                            selectedOption = universityOptions[index].id
                            withAnimation {
                                showOptions = false
                            }
                        }) {
                            Text(universityOptions[index].name)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.textFieldWord)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
                                .background(Color.textFieldBg.opacity(0.01))
                        }
                        .buttonStyle(PlainButtonStyle())
                        // 🛠 Only show divider if NOT the last item:
                        if index != universityOptions.count - 1 {
                            Divider()
                                .frame(height: 1)
                                .background(Color.textFieldFrame.opacity(0.6))
                        }
                    }
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.textFieldBg)
                        .stroke(Color.textFieldFrame, lineWidth: 1)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(0..<renderedOptions.count, id: \.self) { index in
                                renderedOptions[index]
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .frame(height: 165)
                    .transition(.opacity)
                    .animation(.easeInOut, value: showOptions)
                }
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
            }
        }
        .sensoryFeedback(.selection, trigger: showOptions)
    }
}
