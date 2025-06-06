//
//  veygo_apartment_swift_tests.swift
//  veygo-apartment-swift-tests
//
//  Created by Shenghong Zhou on 5/17/25.
//

import Testing
@testable import veygo_apartment_swift

struct veygo_apartment_swift_tests {
    
    @Suite("Age Validator")
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
            #expect(!EmailValidator(email: "", acceptedDomains: []).isValidEmail)
            #expect(!EmailValidator(email: "plainaddress", acceptedDomains: []).isValidEmail)
            #expect(!EmailValidator(email: "@missingusername.com", acceptedDomains: []).isValidEmail)
            #expect(!EmailValidator(email: "username@.com", acceptedDomains: []).isValidEmail)
            #expect(!EmailValidator(email: "username@com", acceptedDomains: []).isValidEmail)
            #expect(!EmailValidator(email: "username@domain..com", acceptedDomains: []).isValidEmail)
            #expect(!EmailValidator(email: "username@domain.", acceptedDomains: []).isValidEmail)
            
            #expect(EmailValidator(email: "example@example.com", acceptedDomains: []).isValidEmail)
            #expect(EmailValidator(email: "user.name+tag+sorting@example.com", acceptedDomains: []).isValidEmail)
            #expect(EmailValidator(email: "user_name@example.co.uk", acceptedDomains: []).isValidEmail)
            #expect(EmailValidator(email: "username@sub.domain.com", acceptedDomains: []).isValidEmail)
        }
        @Test func domainAcceptanceValidation() async throws {
            let acceptedDomains = ["purdue.edu","veygo.rent"]
            #expect(EmailValidator(email: "user@purdue.edu", acceptedDomains: acceptedDomains).isValidUniversity)
            #expect(!EmailValidator(email: "user@gmail.com", acceptedDomains: acceptedDomains).isValidUniversity)
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
    
    @Suite("Phone Number Validator")
    struct phone_number_validator_tests {
        @Test func phoneNumberValidation() async throws {
            #expect(!PhoneNumberValidator(number: "").isValidNumber)
            #expect(!PhoneNumberValidator(number: "1234567890").isValidNumber)
            #expect(!PhoneNumberValidator(number: "123-4567-890").isValidNumber)
            #expect(!PhoneNumberValidator(number: "123-456-789").isValidNumber)
            #expect(!PhoneNumberValidator(number: "123-456-78900").isValidNumber)
            #expect(!PhoneNumberValidator(number: "123-456-789!").isValidNumber)
            #expect(!PhoneNumberValidator(number: "123-45A-7890").isValidNumber)
            #expect(!PhoneNumberValidator(number: "ABC-DEF-GHIJ").isValidNumber)
            #expect(!PhoneNumberValidator(number: "12a-456-7890").isValidNumber)
            
            #expect(PhoneNumberValidator(number: "123-45A-7890").normalizedNumber == "123457890")
            
            #expect(PhoneNumberValidator(number: "123-456-7890").isValidNumber)
            #expect(PhoneNumberValidator(number: "123-456-7890").normalizedNumber == "1234567890")
        }
    }
}
