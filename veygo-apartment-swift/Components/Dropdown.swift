//
//  Dropdown.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/5/25.
//
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

    var universityOptions: [Apartment]

    @State private var showOptions = false

    var body: some View {
        VStack (spacing: 16) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("TextFieldBg"))
                    .stroke(Color("TextFieldFrame"), lineWidth: 1)
                    .frame(height: 53)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        // rental location
                        Text(labelText)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color("FootNote"))
                            .frame(height: 10, alignment: .leading)
                        // University name
                        Text(selectedOption)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("TextFieldWordColor"))
                            .frame(height: 24, alignment: .leading)
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
                            .foregroundColor(Color("Dropdown"))
                            .font(.system(size: 18, weight: .bold))
                            .rotationEffect(.degrees(showOptions ? 180 : 0))
                            .animation(.easeInOut, value: showOptions)
                    }
                    .padding(.trailing, 16)
                }

            }
            if showOptions {
                let renderedOptions = universityOptions.indices.map { index in
                    VStack(spacing: 0) {
                        Button(action: {
                            selectedOption = universityOptions[index].name
                            withAnimation {
                                showOptions = false
                            }
                        }) {
                            Text(universityOptions[index].name)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color("TextFieldWordColor"))
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
                                .background(Color("TextFieldBg").opacity(0.01))
                        }
                        .buttonStyle(PlainButtonStyle())
                        Divider()
                            .frame(height: 1)
                            .background(Color("TextFieldFrame").opacity(0.6))
                    }
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("TextFieldBg"))
                        .stroke(Color("TextFieldFrame"), lineWidth: 1)

                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(0..<renderedOptions.count, id: \.self) { index in
                                renderedOptions[index]
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .frame(height: 165)
                    .transition(.opacity)
                    .animation(.easeInOut, value: showOptions)
                }
            }
        }
    }
}

#Preview {
    let sampleUniversities: [Apartment] = [
        Apartment(
            id: 1,
            name: "Veygo HQ",
            email: "admin@veygo.rent",
            phone: "8334683946",
            address: "101 Foundry Dr, Ste 1200, West Lafayette, IN 47906",
            acceptedSchoolEmailDomain: "veygo.rent",
            freeTierHours: 0,
            freeTierRate: 0,
            silverTierHours: 0,
            silverTierRate: 0,
            goldTierHours: 0,
            goldTierRate: 0,
            platinumTierHours: 0,
            platinumTierRate: 0,
            durationRate: 0,
            liabilityProtectionRate: 0,
            pcdwProtectionRate: 0,
            pcdwExtProtectionRate: 0,
            rsaProtectionRate: 0,
            paiProtectionRate: 0,
            isOperating: true,
            isPublic: true,
            uniId: 1,
            taxes: []
        )
]
    
    StatefulPreviewWrapper("Purdue University") { selected in
        Dropdown(
            selectedOption: selected,
            labelText: .constant("Rental location"),
            universityOptions: sampleUniversities
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
