//
//  Enums.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/12/26.
//

import Foundation

enum VerificationType: String, Codable {
    case email = "Email"
    case phone = "Phone"
}

enum RemoteMgmtType: String, Codable {
    case revers = "Revers"
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

enum PolicyType: String, Codable {
    case rental = "Rental"
    case privacy = "Privacy"
    case membership = "Membership"
    case usage = "Usage"
}
