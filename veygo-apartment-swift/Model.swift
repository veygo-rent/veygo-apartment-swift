//
//  Models.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 6/7/25.
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
    case geotab = "Geotab"
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
    case veygoBadDebt = "VeygoBadDebt"
    case veygoInsurance = "VeygoInsurance"
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

enum TaxType: String, Codable {
    case percent = "Percent"
    case daily = "Daily"
    case fixed = "Fixed"
}

nonisolated struct UsAddress: Equatable, Codable, Hashable {
    var streetAddress: String
    var extendedAddress: String?
    var city: String
    var state: String
    var zipcode: String
}

nonisolated struct RewardTransaction: Identifiable, Equatable, Codable {
    var id: Int
    var agreementId: Int?
    var duration: Double
    var transactionTime: Date
    var renterId: Int
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
    var driversLicenseImage: String?
    var driversLicenseImageSecondary: String?
    var driversLicenseExpiration: String?
    var insuranceIdImage: String?
    var insuranceLiabilityExpiration: String?
    var insuranceCollisionExpiration: String?
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

nonisolated struct Apartment: Identifiable, Equatable, Codable, Hashable, HasName {
    var id: Int
    var name: String
    var timezone: String
    var email: String
    var phone: String
    var address: UsAddress
    var acceptedSchoolEmailDomain: String
    var freeTierHours: Double
    var silverTierHours: Double?
    var silverTierRate: Double?
    var goldTierHours: Double?
    var goldTierRate: Double?
    var platinumTierHours: Double?
    var platinumTierRate: Double?
    var durationRate: Double
    var liabilityProtectionRate: Double?
    var pcdwProtectionRate: Double?
    var pcdwExtProtectionRate: Double?
    var rsaProtectionRate: Double?
    var paiProtectionRate: Double?
    var isOperating: Bool
    var isPublic: Bool
    var uniId: Int
    var mileageRateOverwrite: Double?
    var mileagePackageOverwrite: Double?
    var mileageConversion: Double
}

nonisolated struct NewApartment: Equatable, Codable, HasName {
    var name: String
    var timezone: String
    var email: String
    var phone: String
    var address: String
    var acceptedSchoolEmailDomain: String
    var freeTierHours: Double
    var silverTierHours: Double?
    var silverTierRate: Double?
    var goldTierHours: Double?
    var goldTierRate: Double?
    var platinumTierHours: Double?
    var platinumTierRate: Double?
    var durationRate: Double
    var liabilityProtectionRate: Double?
    var pcdwProtectionRate: Double?
    var pcdwExtProtectionRate: Double?
    var rsaProtectionRate: Double?
    var paiProtectionRate: Double?
    var isOperating: Bool
    var isPublic: Bool
    var uniId: Int
    var mileage_rate_overwrite: Double?
    var mileage_package_overwrite: Double?
    var mileageConversion: Double
}

nonisolated struct Location: Identifiable, Equatable, Codable, Hashable, HasName {
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

nonisolated struct PublishRenterVehicle: Identifiable, Equatable, Codable, Hashable {
    var id: Int
    var vin: String
    var name: String
    var capacity: Int
    var doors: Int
    var smallBags: Int
    var largeBags: Int
    var carplay: Bool
    var laneKeep: Bool
    var licenseNumber: String
    var licenseState: String
    var year: String
    var make: String
    var model: String
    var msrpFactor: Double
    var imageLink: String?
    var odometer: Int
    var tankSize: Double
    var tankLevelPercentage: Int
    var locationId: Int
    var remoteMgmt: RemoteMgmtType
    var requiresOwnInsurance: Bool
}

nonisolated struct PublishAdminVehicle: Identifiable, Equatable, Codable {
    var id: Int
    var name: String
    var vin: String
    var capacity: Int
    var doors: Int
    var smallBags: Int
    var largeBags: Int
    var carplay: Bool
    var laneKeep: Bool
    var available: Bool
    var licenseNumber: String
    var licenseState: String
    var year: String
    var make: String
    var model: String
    var msrpFactor: Double
    var imageLink: String?
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

nonisolated struct DamageSubmission: Identifiable, Equatable, Codable {
    var id: Int
    var reportedBy: Int
    var firstImage: String
    var secondImage: String
    var thirdImage: String?
    var fourthImage: String?
    var description: String
    var processed: Bool
}

nonisolated struct Claim: Identifiable, Equatable, Codable {
    var id: Int
    var note: String?
    var time: Date
    var agreementId: Int
    var adminFee: Double?
    var towCharge: Double?
    var citation: Double?
}

nonisolated struct Damage: Identifiable, Equatable, Codable {
    var id: Int
    var note: String
    var recordDate: Date
    var occurDate: Date
    var standardCoordinationXPercentage: Int
    var standardCoordinationYPercentage: Int
    var firstImage: String
    var secondImage: String
    var thirdImage: String?
    var fourthImage: String?
    var fixedDate: Date?
    var fixedAmount: Double?
    var depreciation: Double?
    var lostOfUse: Double?
    var claimId: Int
    var vehicleId: Int
}

nonisolated struct VehicleSnapshot: Identifiable, Equatable, Codable {
    var id: Int
    var leftImage: String
    var rightImage: String
    var frontImage: String
    var backImage: String
    var time: Date
    var odometer: Int
    var level: Int
    var vehicleId: Int
    var rearRight: String
    var rearLeft: String
    var frontRight: String
    var frontLeft: String
    var dashboard: String?
    var renterId: Int
}

nonisolated struct PublishPromo: Identifiable, Equatable, Codable {
    var id: String { code }
    var code: String
    var name: String
    var amount: Double
    var isEnabled: Bool
    var isOneTime: Bool
    var exp: Date
}

nonisolated struct Agreement: Identifiable, Equatable, Codable {
    var id: Int
    var confirmation: String
    var status: AgreementStatus
    var userName: String
    var userDateOfBirth: String
    var userEmail: String
    var userPhone: String
    var userBillingAddress: UsAddress
    var rsvpPickupTime: Date
    var rsvpDropOffTime: Date
    var liabilityProtectionRate: Double?
    var pcdwProtectionRate: Double?
    var pcdwExtProtectionRate: Double?
    var rsaProtectionRate: Double?
    var paiProtectionRate: Double?

    var actualPickupTime: Date?
    var actualDropOffTime: Date?

    var msrpFactor: Double
    var durationRate: Double
    var vehicleId: Int
    var vehicleSnapshotBefore: Int?
    var vehicleSnapshotAfter: Int?

    var renterId: Int
    var paymentMethodId: Int
    var promoId: String?
    var locationId: Int
    var manualDiscount: Double?
    var mileagePackageId: Int?
    var mileageRate: Double?
    var mileageConversion: Double
    var utilizationFactor: Double
    var dateOfCreation: Date
}

nonisolated struct Charge: Identifiable, Equatable, Codable {
    var id: Int
    var name: String
    var time: Date
    var amount: Double
    var note: String?
    var agreementId: Int
    var vehicleId: Int
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
    var paymentMethodId: Int?
    var amountAuthorized: Double
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

nonisolated struct Tax: Identifiable, Equatable, Codable, HasName {
    var id: Int
    var name: String
    var multiplier: Double
    var isSalesTax: Bool
    var taxType: TaxType
}

nonisolated struct MileagePackage: Identifiable, Equatable, Codable {
    var id: Int
    var miles: Int
    var discountedRate: Int
    var isActive: Bool
}

nonisolated struct NewMileagePackage: Equatable, Codable {
    var miles: Int
    var discountedRate: Int
    var isActive: Bool
}

nonisolated struct ErrorResponse: Equatable, Codable {
    var title: String
    var message: String
    
    static let WRONG_PROTOCOL = ErrorResponse(title: "Wrong Protocol", message: "Please use correct protocol (eg. https).")
    
    static let E400 = ErrorResponse(title: "Bad Request", message: "The data you provided is not valid.")
    static let E401 = ErrorResponse(title: "Not Authenticated", message: "Please log in again to access this resource.")
    static let E402 = ErrorResponse(title: "Payment Declined", message: "Please try a different card.")
    static let E403 = ErrorResponse(title: "Forbidden", message: "You do not have permission to access this resource.")
    static let E405 = ErrorResponse(title: "Method Not Allowed", message: "The method you have attempted to use is not supported by this endpoint.")
    static let E406 = ErrorResponse(title: "Not Acceptable", message: "The requested format is not supported.")
    static let E409 = ErrorResponse(title: "Conflict", message: "The requested resource already exists.")
    
    static let E500 = ErrorResponse(title: "Internal Server Error", message: "An unexpected error occurred. Please try again later.")
    static let E501 = ErrorResponse(title: "Not Implemented", message: "This feature is not yet available.")
    
    static let E_TIME_OUT = ErrorResponse(title: "Request Timeout", message: "The request timed out. Please try again.")
    static let E_NO_INTERNET = ErrorResponse(title: "No Internet Connection", message: "Please check your internet connection and try again.")
    
    static let E_DEFAULT = ErrorResponse(title: "Unknown Error", message: "This shouldn't have happened. Please contact support.")
}
