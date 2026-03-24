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
    var schoolTimezoneIdentifier: String? = nil
    
    private var minimumStartDate: Date {
        Date().nextQuarterHour().addingTimeInterval(15 * 60)
    }

    private var minimumEndDate: Date {
        max(startDate.addingTimeInterval(30 * 60), Date().nextQuarterHour().addingTimeInterval(45 * 60))
    }
    
    private var displayTimeZone: TimeZone {
        guard let schoolTimezoneIdentifier,
              let schoolTimeZone = TimeZone(identifier: schoolTimezoneIdentifier) else {
            return .current
        }
        return schoolTimeZone
    }
    
    private var shouldShowSchoolTime: Bool {
        guard let schoolTimezoneIdentifier else { return false }
        return TimeZone(identifier: schoolTimezoneIdentifier) != nil
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = displayTimeZone
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = displayTimeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formattedSchoolNow(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = displayTimeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return "Local time: \(formatter.string(from: date))"
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("TextFieldBg"))
                .stroke(Color("TextFieldFrame"), lineWidth: 1)
                .onAppear {
                    if startDate < minimumStartDate {
                        startDate = minimumStartDate
                    }
                    if endDate < minimumEndDate {
                        endDate = minimumEndDate
                    }
                    if endDate > minimumEndDate.addingTimeInterval(4*7*24*3600) {
                        endDate = minimumEndDate.addingTimeInterval(4*7*24*3600)
                    }
                }
                .onChange(of: startDate) { _, newValue in
                    if endDate < minimumEndDate {
                        endDate = minimumEndDate
                    }
                    if endDate > minimumEndDate.addingTimeInterval(4*7*24*3600) {
                        endDate = minimumEndDate.addingTimeInterval(4*7*24*3600)
                    }
                }
            VStack(spacing: 0) {
                if shouldShowSchoolTime {
                    TimelineView(.periodic(from: .now, by: 5)) { context in
                        Text(formattedSchoolNow(context.date))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color("FootNote"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .onChange(of: context.date) { _, _ in
                                if startDate < minimumStartDate {
                                    startDate = minimumStartDate
                                }
                                if startDate > minimumStartDate.addingTimeInterval(6*7*24*3600) {
                                    startDate = minimumStartDate.addingTimeInterval(6*7*24*3600)
                                }
                            }
                    }
                    
                    Divider()
                }
                
                HStack(spacing: 0) {
                    // 左
                    VStack(alignment: .center, spacing: 4) {
                        Text(formattedDate(startDate))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color("FootNote"))
                        
                        Text(formattedTime(startDate))
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
                        Text(formattedDate(endDate))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color("FootNote"))
                        
                        Text(formattedTime(endDate))
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(Color("TextFieldWordColor"))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture { showEndPicker.toggle() }
                }
                .frame(height: 71)
            }
            // 起始日期选择器
            .modifier(optionalDateSheet(showPicker: $showStartPicker, pickerView: {
                AnyView(
                    VStack {
                        DatePicker("Select Start Date & Time", selection: $startDate, in: minimumStartDate...minimumStartDate.addingTimeInterval(6*7*24*3600), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .environment(\.timeZone, displayTimeZone)
                            .onAppear {
                                UIDatePicker.appearance().minuteInterval = 15
                            }
                        PrimaryButton(text: "Complete") {
                            showStartPicker.toggle()
                        }
                    }.padding(.horizontal)
                )
            }, isEditMode: isEditMode))
            // 结束日期选择器
            .modifier(optionalDateSheet(showPicker: $showEndPicker, pickerView: {
                AnyView(
                    VStack {
                        DatePicker("Select End Date & Time", selection: $endDate, in: minimumEndDate...minimumEndDate.addingTimeInterval(4*7*24*3600), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .environment(\.timeZone, displayTimeZone)
                            .onAppear {
                                UIDatePicker.appearance().minuteInterval = 15
                            }
                        PrimaryButton(text: "Complete") {
                            showEndPicker.toggle()
                        }
                    }.padding(.horizontal)
                )
            }, isEditMode: isEditMode))
        }
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
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
