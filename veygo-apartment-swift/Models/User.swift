//
//  User.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/12/26.
//

import Foundation

struct PublishRenter: Identifiable, Equatable, Codable {
    var id: Int
    var name: String
    var studentEmail: String
    var studentEmailExpiration: String?
    var phone: String
    var phoneIsVerified: Bool
    var dateOfBirth: String
    var profilePicture: String?
    var gender: Gender?
    var dateOfRegistration: Date
    var driversLicenseNumber: String?
    var driversLicenseStateRegion: String?
    var driversLicenseImage: String?
    var driversLicenseImageSecondary: String?
    var driversLicenseExpiration: String?
    var insuranceIdImage: String?
    var insuranceLiabilityExpiration: String?
    var insuranceCollisionValid: Bool
    var leaseAgreementImage: String?
    var apartmentId: Int
    var leaseAgreementExpiration: String?
    var billingAddress: UsAddress?
    var signatureImage: String?
    var signatureDatetime: Date?
    var planTier: PlanTier
    var planRenewalDay: String
    var planExpireMonthYear: String
    var isPlanAnnual: Bool
    var employeeTier: EmployeeTier
    var subscriptionPaymentMethodId: Int?
    var requiresSecondaryDriverLic: Bool
    var planTotalAvailability: FlexDecimal
}

struct NewRenter: Codable {
    var name: String?
    var dateOfBirth: String?     // MM/DD/YYYY
    var phone: String?
    var studentEmail: String?
    var password: String?
}
