//
//  Validators.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 5/29/25.
//

import Foundation

public struct AgeValidator {
    let dob: String
    
    var parsedDate: Date? {
        guard dob.count == 10 else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dob)
    }
    
    var isValidFormat: Bool {
        parsedDate != nil
    }
    
    var isOver18: Bool {
        guard let birthDate = parsedDate else { return false }
        let calendar = Calendar.current
        if let eighteenYearsLater = calendar.date(byAdding: .year, value: 18, to: birthDate) {
            return Date() >= eighteenYearsLater
        }
        return false
    }
}

public struct EmailValidator {
    let email: String
    var isValidEmail: Bool {
        // RFC 5321 limit (commonly used threshold)
        guard email.count <= 254 else { return false }
        
        let pattern = #"(?i)^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9-](?:[a-z0-9-]{0,61}[a-z0-9])+(?:\.[a-z0-9-](?:[a-z0-9-]{0,61}[a-z0-9])+)+$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(email.startIndex..<email.endIndex, in: email)
        return regex?.firstMatch(in: email, options: [], range: range) != nil
    }
}
