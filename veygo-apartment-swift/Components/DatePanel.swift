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
    
    var body: some View {
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
            Rectangle()
                .fill(Color("TextFieldFrame").opacity(0.3))
                .frame(width: 2, height: 71)
            
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
        .frame(width: 338, height: 71)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("TextFieldFrame").opacity(0.3), lineWidth: 2)
        )
        // 起始日期选择器
        .sheet(isPresented: $showStartPicker) {
            DatePicker("Select Start Date & Time", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
        }
        // 结束日期选择器
        .sheet(isPresented: $showEndPicker) {
            DatePicker("Select End Date & Time", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
        }
    }
}

#Preview {
    StatefulPreviewWrapper(Date()) { startDate in
        StatefulPreviewWrapper(Date().addingTimeInterval(3600)) { endDate in
            DatePanel(
                startDate: startDate,
                endDate: endDate
            )
        }
    }
}

