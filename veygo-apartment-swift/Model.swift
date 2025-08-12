//
//  UserModel.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/27/25.
//

import Foundation

enum VerificationType: String, Codable {
    case email = "Email"
    case phone = "Phone"
}

enum RemoteMgmtType: String, Codable {
    case revers = "Revers"
    case smartcar = "Smartcar"
    case tesla = "Tesla"
    case none = "None"
}

enum AgreementStatus: String, Codable {
    case rental = "Rental"
    case void = "Void"
    case canceled = "Canceled"
}

enum EmployeeTier: String, Codable {
    case user = "User"
    case generalEmployee = "GeneralEmployee"
    case maintenance = "Maintenance"
    case admin = "Admin"
}

enum PaymentType: String, Codable {
    case canceled = "Canceled"
    case processing = "Processing"
    case requiresAction = "RequiresAction"
    case requiresCapture = "RequiresCapture"
    case requiresConfirmation = "RequiresConfirmation"
    case requiresPaymentMethod = "RequiresPaymentMethod"
    case succeeded = "Succeeded"
}

enum PlanTier: String, Codable {
    case free = "Free"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
}

enum Gender: String, Codable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case pnts = "PNTS"
}

enum TransactionType: String, Codable {
    case credit = "Credit"
    case cash = "Cash"
}

nonisolated struct RentalTransaction: Identifiable, Equatable, Codable {
    var id: Int
    var agreementId: Int
    var transactionType: TransactionType
    var duration: Double
    var transactionTime: Date
}

nonisolated struct PublishRenter: Identifiable, Equatable, Codable {
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
    var driversLicenseExpiration: String? // Admin needs to verify
    var insuranceLiabilityExpiration: String? // Admin needs to verify
    var insuranceCollisionExpiration: String? // Admin needs to verify
    var apartmentId: Int
    var leaseAgreementExpiration: String? // Admin needs to verify
    var billingAddress: String?
    var signatureDatetime: Date?
    var planTier: PlanTier
    var planRenewalDay: String
    var planExpireMonthYear: String
    var planAvailableDuration: Double
    var isPlanAnnual: Bool
    var employeeTier: EmployeeTier
    var subscriptionPaymentMethodId: Int?
}

nonisolated struct PublishPaymentMethod: Identifiable, Equatable, Codable {
    var id: Int
    var cardholderName: String
    var maskedCardNumber: String
    var network: String
    var expiration: String
    var nickname: String?
    var isEnabled: Bool
    var renterId: Int
    var lastUsedDateTime: Date?
    var cdwEnabled: Bool
}

nonisolated struct Apartment: Identifiable, Equatable, Codable, HasName {
    var id: Int
    var name: String
    var email: String
    var phone: String
    var address: String
    var acceptedSchoolEmailDomain: String
    var freeTierHours: Double
    var freeTierRate: Double
    var silverTierHours: Double
    var silverTierRate: Double
    var goldTierHours: Double
    var goldTierRate: Double
    var platinumTierHours: Double
    var platinumTierRate: Double
    var durationRate: Double
    var liabilityProtectionRate: Double
    var pcdwProtectionRate: Double
    var pcdwExtProtectionRate: Double
    var rsaProtectionRate: Double
    var paiProtectionRate: Double
    var isOperating: Bool
    var isPublic: Bool
    var uniId: Int
    var taxes: [Int?]
}

nonisolated struct NewApartment: Equatable, Codable, HasName {
    var name: String
    var email: String
    var phone: String
    var address: String
    var acceptedSchoolEmailDomain: String
    var freeTierHours: Double
    var freeTierRate: Double
    var silverTierHours: Double
    var silverTierRate: Double
    var goldTierHours: Double
    var goldTierRate: Double
    var platinumTierHours: Double
    var platinumTierRate: Double
    var durationRate: Double
    var liabilityProtectionRate: Double
    var pcdwProtectionRate: Double
    var pcdwExtProtectionRate: Double
    var rsaProtectionRate: Double
    var paiProtectionRate: Double
    var isOperating: Bool
    var isPublic: Bool
    var uniId: Int
    var taxes: [Int?]
}

nonisolated struct Location: Identifiable, Equatable, Codable, HasName {
    var id: Int
    var apartmentId: Int
    var name: String
    var description: String?
    var latitude: Double
    var longitude: Double
    var isOperational: Bool
}

nonisolated struct TransponderCompany: Identifiable, Equatable, Codable {
    var id: Int
    var name: String
    var correspondingKeyForVehicleId: String
    var correspondingKeyForTransactionName: String
    var customPrefixForTransactionName: String
    var correspondingKeyForTransactionTime: String
    var correspondingKeyForTransactionAmount: String
    var timestampFormat: String
    var timezone: String?
}

nonisolated struct PublishVehicle: Identifiable, Equatable, Codable {
    var id: Int
    var vin: String
    var name: String
    var licenseNumber: String
    var licenseState: String
    var year: String
    var make: String
    var model: String
    var msrpFactor: Double
    var odometer: Int
    var tankSize: Double
    var tankLevelPercentage: Int
    var locationId: Int
    var remoteMgmt: RemoteMgmtType
    var remoteMgmtId: String
    var requiresOwnInsurance: Bool
}

nonisolated struct PublishAdminVehicle: Identifiable, Equatable, Codable {
    var id: Int
    var vin: String
    var name: String
    var available: Bool
    var licenseNumber: String
    var licenseState: String
    var year: String
    var make: String
    var model: String
    var msrpFactor: Double
    var odometer: Int
    var tankSize: Double
    var tankLevelPercentage: Int
    var firstTransponderNumber: String?
    var firstTransponderCompanyId: Int?
    var secondTransponderNumber: String?
    var secondTransponderCompanyId: Int?
    var thirdTransponderNumber: String?
    var thirdTransponderCompanyId: Int?
    var fourthTransponderNumber: String?
    var fourthTransponderCompanyId: Int?
    var locationId: Int
    var remoteMgmt: RemoteMgmtType
    var remoteMgmtId: String
    var requiresOwnInsurance: Bool
}

nonisolated struct PublishDamageSubmission: Identifiable, Equatable, Codable {
    var id: Int
    var reportedBy: Int
    var description: String
    var processed: Bool
}

nonisolated struct PublishDamage: Identifiable, Equatable, Codable {
    var id: Int
    var note: String
    var recordDate: Date
    var occurDate: Date
    var standardCoordinationXPrecentage: Int
    var standardCoordinationYPrecentage: Int
    var fixedDate: Date?
    var fixedAmount: Double?
    var agreementId: Int?
}

nonisolated struct Promo: Identifiable, Equatable, Codable {
    var id: String { code }
    var code: String
    var name: String
    var amount: Double
    var isEnabled: Bool
    var isOneTime: Bool
    var exp: Date
    var userId: Int
    var aptId: Int
    var uniId: Int
}

nonisolated struct Agreement: Identifiable, Equatable, Codable {
    var id: Int
    var confirmation: String
    var status: AgreementStatus
    var userName: String
    var userDateOfBirth: String
    var userEmail: String
    var userPhone: String
    var userBillingAddress: String
    var rsvpPickupTime: Date
    var rsvpDropOffTime: Date
    var liabilityProtectionRate: Double
    var pcdwProtectionRate: Double
    var pcdwExtProtectionRate: Double
    var rsaProtectionRate: Double
    var paiProtectionRate: Double
    
    var actualPickupTime: Date?
    var pickupOdometer: Int?
    var pickupLevel: Int?
    
    var actualDropOffTime: Date?
    var dropOffOdometer: Int?
    var dropOffLevel: Int?
    var vehicleSnapshotBefore: Int?
    
    var msrpFactor: Double
    var durationRate: Double
    var vehicleId: Int
    var vehicleSnapshotAfter: Int?
    
    var renterId: Int
    var paymentMethodId: Int
    var promoId: String?
    
    var damageIds: [Int?]
    
    var taxes: [Int?]
    var locationId: Int
}

nonisolated struct Charge: Identifiable, Equatable, Codable {
    var id: Int
    var name: String
    var time: Date
    var amount: Double
    var note: String?
    var agreementId: Int?
    var vehicleId: Int
    var checksum: String
    var transponderCompanyId: Int?
    var vehicleIdentifier: String?
}

nonisolated struct Payment: Identifiable, Equatable, Codable {
    var id: Int
    var paymentType: PaymentType
    var time: Date
    var amount: Double
    var note: String?
    var referenceNumber: String?
    var agreementId: Int?
    var renterId: Int
    var paymentMethodId: Int
    var amountAuthorized: Double?
    var captureBefore: Date?
    var isDeposit: Bool
}

nonisolated struct DoNotRentList: Identifiable, Equatable, Codable {
    var id: Int
    var name: String?
    var email: String?
    var phone: String?
    var note: String
    var exp: String?
}

struct Tax: Identifiable, Equatable, Codable, HasName {
    var id: Int
    var name: String
    var multiplier: Double
    var isEffective: Bool
}
