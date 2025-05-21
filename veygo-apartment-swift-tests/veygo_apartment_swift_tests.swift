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
    
}
