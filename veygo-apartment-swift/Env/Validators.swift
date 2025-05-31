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
    let acceptedDomains: [String]
    var isValidEmail: Bool {
        // RFC 5321 limit (commonly used threshold)
        guard email.count <= 254 else { return false }
        
        let pattern = #"(?i)^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-z0-9-](?:[a-z0-9-]{0,61}[a-z0-9])+(?:\.[a-z0-9-](?:[a-z0-9-]{0,61}[a-z0-9])+)+$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(email.startIndex..<email.endIndex, in: email)
        return regex?.firstMatch(in: email, options: [], range: range) != nil
    }
    var isValidUniversity: Bool {
        guard let domain = email.split(separator: "@").last.map(String.init) else {
            return false
        }
        return acceptedDomains.contains(domain)
    }
}

public struct NameValidator {
    let name: String
    var isValidName: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ")
        
        // Must have at least two parts (e.g., first and last name)
        guard parts.count >= 2 else { return false }
        
        // Each part must start with an uppercase letter followed by lowercase letters
        for (index, part) in parts.enumerated() {
            if index == 0 || index == parts.count - 1 {
                guard part.count >= 2 else { return false }
            }
            guard let first = part.first, first.isUppercase else { return false }
            let rest = part.dropFirst()
            guard rest.allSatisfy({ $0.isLowercase }) else { return false }
        }
        
        return true
    }
}

public struct PhoneNumberValidator {
    let number: String
    var isValidNumber: Bool {
        let pattern = #"^\d{3}-\d{3}-\d{4}$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(number.startIndex..<number.endIndex, in: number)
        return regex?.firstMatch(in: number, options: [], range: range) != nil
    }
    var normalizedNumber: String {
        number.filter { $0.isNumber }
    }
}
