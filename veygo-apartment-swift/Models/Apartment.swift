//
//  Apartment.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/12/26.
//

import Foundation

struct Apartment: Identifiable, Equatable, Decodable, Hashable, HasName {
    var id: Int
    var name: String
    var timezone: String
    var email: String
    var phone: String
    var address: UsAddress
    var acceptedSchoolEmailDomain: String
    var freeTierHours: FlexDecimal
    var silverTierHours: FlexDecimal
    var silverTierRate: FlexDecimal
    var goldTierHours: FlexDecimal
    var goldTierRate: FlexDecimal
    var platinumTierHours: FlexDecimal
    var platinumTierRate: FlexDecimal
    var durationRate: FlexDecimal
    var liabilityProtectionRate: FlexDecimal?
    var pcdwProtectionRate: FlexDecimal?
    var pcdwExtProtectionRate: FlexDecimal?
    var rsaProtectionRate: FlexDecimal?
    var paiProtectionRate: FlexDecimal?
    var isOperating: Bool
    var isPublic: Bool
    var uniId: Int
    var mileageRateOverwrite: FlexDecimal?
    var mileagePackageOverwrite: FlexDecimal?
    var mileageConversion: FlexDecimal
    var latitudeLowerBound: Double
    var latitudeHigherBound: Double
    var longitudeLowerBound: Double
    var longitudeHigherBound: Double
}

struct Location: Identifiable, Equatable, Decodable, Hashable, HasName {
    var id: Int
    var apartmentId: Int
    var name: String
    var description: String?
    var latitude: Double
    var longitude: Double
    var isOperational: Bool
    var latitudeLowerDound: Double?
    var latitudeHigherBound: Double?
    var longitudeLowerBound: Double?
    var longitudeHigherBound: Double?
}

struct Tax: Identifiable, Equatable, Decodable, Hashable, HasName {
    var id: Int
    var name: String
    var multiplier: FlexDecimal
    var isSalesTax: Bool
    var taxType: TaxType
    var isDepositTax: Bool
    var threshold: Int?
    var isLower: Bool?
}
