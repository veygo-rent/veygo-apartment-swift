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

extension Apartment {
    func localizedDate(for date: Date) -> String {
        let currentTimeZone = TimeZone.current
        let apartmentTimeZone = TimeZone(identifier: self.timezone) ?? currentTimeZone

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = apartmentTimeZone
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let formattedDate = dateFormatter.string(from: date)

        let currentAbbreviation = currentTimeZone.abbreviation(for: date)
        let apartmentAbbreviation = apartmentTimeZone.abbreviation(for: date)

        if apartmentAbbreviation != nil && apartmentAbbreviation != currentAbbreviation {
            return "\(formattedDate) \(apartmentAbbreviation!)"
        } else {
            return formattedDate
        }
    }
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

struct LocationWithVehicles: Decodable, Identifiable {
    var location: Location
    var vehicles: [VehicleWithBlockedDurations]
    var id: Location.ID { location.id }
    var duration: TimeInterval? = nil
}
