//
//  DateTime.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 7/30/25.
//

import Foundation

nonisolated public func dateFromYYYYMMDD(_ raw: String) -> Date? {
    // Re-use the same formatter for every call
    struct Static {
        nonisolated static let formatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.timeZone = TimeZone(secondsFromGMT: 0)
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }()
    }
    
    return Static.formatter.date(from: raw)
}
