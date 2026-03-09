//
//  DateTime.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 7/30/25.
//

import Foundation

struct VeygoDatetimeStandard {
    nonisolated static let shared = VeygoDatetimeStandard()
    nonisolated let yyyyMMddDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    nonisolated let usStandardDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/dd/yyyy"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    
    func formattedDateTime(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today, " + timeFormatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow, " + timeFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday, " + timeFormatter.string(from: date)
        } else {
            return fullDateFormatter.string(from: date)
        }
    }

    private var timeFormatter: DateFormatter {
        let df = DateFormatter()
        df.timeStyle = .short       // "6:10 PM"
        return df
    }

    private var fullDateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "MMM d, h:mm a"
        return df
    }
    
    func mediumLengthDateString(from date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }
}

struct VeygoJsonStandard {
    nonisolated static let shared = VeygoJsonStandard()
    nonisolated let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
    nonisolated let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()
}

struct VeygoCurrencyStandard {
    nonisolated static let shared = VeygoCurrencyStandard()
    nonisolated let dollarFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    nonisolated let centFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_US_POSIX")
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        f.multiplier = 100
        f.positiveSuffix = "¢"
        f.negativeSuffix = "¢"
        return f
    }()
}
