//
//  Dropdown.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/5/25.
//

import SwiftUI

struct Dropdown: View {
    @Binding var selectedOption: String
    @Binding var labelText: String
    
    @State private var showOptions = false
    private let options = ["Purdue University", "Indiana University"]
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Frame"), lineWidth: 1)
                .frame(width: 338, height: 53)
            
            VStack(spacing: 4) {
                // rental location
                Text(labelText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("Terms"))
                    .frame(width: 261.09, height: 10, alignment: .leading)
                    .padding(.leading, -26)
                
                HStack(spacing: 0) {
                    // University name
                    Text(selectedOption)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color("TextFieldWordColor"))
                        .frame(width: 241, height: 24, alignment: .leading)
                        .padding(.leading, -30)
                    
                    // DD Button
                    Button(action: {
                        showOptions.toggle()
                    }) {
                        Image(systemName: "chevron.down")
                            .resizable()
                            .frame(width: 15, height: 7)
                            .foregroundColor(Color("TextFieldWordColor"))
                            .font(.system(size: 18, weight: .bold))
                    }
                    .offset(x: 28, y: -4)
                }
            }
            .frame(width: 338, height: 53)
        }
        .overlay(
            VStack(spacing: 0) {
                if showOptions {
                    ForEach(options, id: \.self) { option in
                        Text(option)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("TextFieldWordColor"))
                            .frame(width: 338, height: 44, alignment: .center)
                            .background(Color.white)
                            .onTapGesture {
                                selectedOption = option
                                showOptions = false
                            }
                    }
                }
            }
            .offset(y: 53)
            , alignment: .topLeading
        )
    }
}

#Preview {
    StatefulPreviewWrapper("Purdue University") { selected in
        Dropdown(
            selectedOption: selected,
            labelText: .constant("Rental location")
        )
    }
}

struct StatefulPreviewWrapper<T: Equatable>: View {
    @State private var value: T
    private var content: (Binding<T>) -> AnyView
    
    init(_ value: T, @ViewBuilder content: @escaping (Binding<T>) -> some View) {
        self._value = State(initialValue: value)
        self.content = { binding in AnyView(content(binding)) }
    }
    
    var body: some View {
        content($value)
    }
}
