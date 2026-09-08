//
//  Datetime.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/7/26.
//

import Foundation

extension Date {
    /// Returns the next quarter-hour date after the current date.
    func nextQuarterHour() -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: self)
        let remainder = minute % 15
        let minutesToAdd = remainder == 0 ? 15 : 15 - remainder

        let dateWithoutSeconds = calendar.date(
            bySettingHour: calendar.component(.hour, from: self),
            minute: minute,
            second: 0,
            of: self
        )!

        return calendar.date(byAdding: .minute, value: minutesToAdd, to: dateWithoutSeconds)!
    }
}
