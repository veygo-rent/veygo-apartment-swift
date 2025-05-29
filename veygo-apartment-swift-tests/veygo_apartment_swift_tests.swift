//
//  veygo_apartment_swift_tests.swift
//  veygo-apartment-swift-tests
//
//  Created by Shenghong Zhou on 5/17/25.
//

import Testing
@testable import veygo_apartment_swift

struct veygo_apartment_swift_tests {
    
    @Suite("Front End Age Check")
    struct front_end_age_check {
        @Test func dateValidating() async throws {
            var validator = AgeValidator(dob: "09")
            #expect(!validator.isValidFormat)
            validator = AgeValidator(dob: "09/01/2000")
            #expect(validator.isValidFormat)
            validator = AgeValidator(dob: "09/01/200")
            #expect(!validator.isValidFormat)
        }
        
        @Test func ageValidating() async throws {
            #expect(AgeValidator(dob: "09/26/2001").isOver18)
            #expect(!AgeValidator(dob: "12/31/2024").isOver18)
        }
    }
    
    @Suite("Email Validator")
    struct email_validator_tests {
        @Test func emailFormatValidation() async throws {
            #expect(!EmailValidator(email: "").isValidEmail)
            #expect(!EmailValidator(email: "plainaddress").isValidEmail)
            #expect(!EmailValidator(email: "@missingusername.com").isValidEmail)
            #expect(!EmailValidator(email: "username@.com").isValidEmail)
            #expect(!EmailValidator(email: "username@com").isValidEmail)
            #expect(!EmailValidator(email: "username@domain..com").isValidEmail)
            #expect(!EmailValidator(email: "username@domain.").isValidEmail)
            
            #expect(EmailValidator(email: "example@example.com").isValidEmail)
            #expect(EmailValidator(email: "user.name+tag+sorting@example.com").isValidEmail)
            #expect(EmailValidator(email: "user_name@example.co.uk").isValidEmail)
            #expect(EmailValidator(email: "username@sub.domain.com").isValidEmail)
        }
    }
    
    @Suite("Name Validator")
    struct name_validator_tests {
        @Test func nameValidation() async throws {
            #expect(!NameValidator(name: "").isValidName)
            #expect(!NameValidator(name: "john").isValidName) // Only one name
            #expect(!NameValidator(name: "john doe").isValidName) // Lowercase
            #expect(!NameValidator(name: "J Doe").isValidName) // Too short
            #expect(!NameValidator(name: "Jo D").isValidName) // Last name too short
            #expect(!NameValidator(name: "Jo Do3").isValidName) // Contains number
            #expect(!NameValidator(name: "Jo ").isValidName) // Not full name
            
            #expect(NameValidator(name: "John Doe").isValidName)
            #expect(NameValidator(name: "Alice Smith").isValidName)
            #expect(NameValidator(name: "Mary Jane").isValidName)
            #expect(NameValidator(name: "Steve Paul Jobs").isValidName)
            #expect(NameValidator(name: "Steve P Jobs").isValidName)
        }
    }
}
