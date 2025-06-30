//
//  DatePanel.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 6/6/25.
//

import SwiftUI

struct DatePanel: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    @State private var showStartPicker = false
    @State private var showEndPicker = false
    
    var isEditMode: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("TextFieldBg"))
                .stroke(Color("TextFieldFrame"), lineWidth: 1)
            HStack(spacing: 0) {
                // 左
                VStack(alignment: .center, spacing: 4) {
                    Text(startDate.formatted(date: .long, time: .omitted))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color("FootNote"))
                    
                    Text(startDate.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(Color("TextFieldWordColor"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture { showStartPicker.toggle() }
                
                // 中
                Divider()
                    .frame(width: 1, height: 71)
                
                // 右
                VStack(alignment: .center, spacing: 4) {
                    Text(endDate.formatted(date: .long, time: .omitted))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color("FootNote"))
                    
                    Text(endDate.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(Color("TextFieldWordColor"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture { showEndPicker.toggle() }
            }
            .frame(height: 71)
            // 起始日期选择器
            .modifier(optionalDateSheet(showPicker: $showStartPicker, pickerView: {
                AnyView(
                    VStack {
                        DatePicker("Select Start Date & Time", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                        PrimaryButtonLg(text: "Complete") {
                            showStartPicker.toggle()
                        }
                    }.padding(.horizontal)
                )
            }, isEditMode: isEditMode))
            // 结束日期选择器
            .modifier(optionalDateSheet(showPicker: $showEndPicker, pickerView: {
                AnyView(
                    VStack {
                        DatePicker("Select End Date & Time", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                        PrimaryButtonLg(text: "Complete") {
                            showEndPicker.toggle()
                        }
                    }.padding(.horizontal)
                )
            }, isEditMode: isEditMode))
        }
    }
    
    private struct optionalDateSheet: ViewModifier {
        @Binding var showPicker: Bool
        
        var pickerView: () -> AnyView
        var isEditMode: Bool

        func body(content: Content) -> some View {
            if isEditMode {
                content
                    .sheet(isPresented: $showPicker) {
                        pickerView()
                            .presentationDetents([.height(500)])
                    }
            } else {
                content
            }
        }
    }
}

#Preview {
    StatefulPreviewWrapper(Date()) { startDate in
        StatefulPreviewWrapper(Date().addingTimeInterval(3600)) { endDate in
            DatePanel(
                startDate: startDate,
                endDate: endDate, isEditMode: true
            )
        }
    }
}

