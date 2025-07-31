//
//  Extentions.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 7/17/25.
//

import Foundation
internal import Combine

extension Array where Element: Identifiable, Element.ID == Int {
    func getItemBy(id: Int) -> Element? {
        return self.first { $0.id == id }
    }
}

extension DoNotRentList {
    func isValid() -> Bool {
        if let expUnwrapped = self.exp {
            let expDate = dateFromYYYYMMDD(expUnwrapped)!
            let now = Date()
            if expDate < now {
                return false
            } else {
                return true
            }
        } else {
            return true
        }
    }
}

extension PublishRenter {
    func emailIsValid() -> Bool {
        if let expUnwrapped = self.studentEmailExpiration {
            let expDate = dateFromYYYYMMDD(expUnwrapped)!
            let now = Date()
            if expDate < now {
                return false
            } else {
                return true
            }
        } else {
            return false
        }
    }
}

protocol HasName {
    var name: String { get }
}

class UserSession: ObservableObject {
    @Published var user: PublishRenter? = nil
}

class SignupSession: ObservableObject {
    @Published var name: Optional<String> = nil
    @Published var date_of_birth: Optional<String> = nil  // MM/DD/YYYY
    @Published var phone: Optional<String> = nil
    @Published var student_email: Optional<String> = nil
    @Published var password: Optional<String> = nil
}
