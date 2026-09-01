//
//  Agreement.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/1/26.
//

import Foundation

struct Agreement: Identifiable, Equatable, Codable {
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
    var liabilityProtectionRate: FlexDecimal?
    var pcdwProtectionRate: FlexDecimal?
    var pcdwExtProtectionRate: FlexDecimal?
    var rsaProtectionRate: FlexDecimal?
    var paiProtectionRate: FlexDecimal?

    var actualPickupTime: Date?
    var actualDropOffTime: Date?

    var msrpFactor: FlexDecimal
    var durationRate: FlexDecimal
    var vehicleId: Int
    var vehicleSnapshotBefore: Int?
    var vehicleSnapshotAfter: Int?

    var renterId: Int
    var paymentMethodId: Int
    var promoId: String?
    var locationId: Int
    var manualDiscount: FlexDecimal?
    var mileagePackageId: Int?
    var mileageRate: FlexDecimal?
    var mileageConversion: FlexDecimal
    var utilizationFactor: FlexDecimal
    var dateOfCreation: Date
    
    var minimumEarningRate: FlexDecimal
    var depositPmtId: Int?
}

struct TripInfo: Codable, Identifiable {
    var id: Agreement.ID { agreement.id }
    let agreement: Agreement
    let apartmentTimezone: String
    let locationName: String
    let vehicleName: String
}

extension TripInfo {
    func localizedStartDate() -> String {
        let currentTimeZone = TimeZone.current
        let apartmentTimeZone = TimeZone(identifier: self.apartmentTimezone) ?? currentTimeZone

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = apartmentTimeZone
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let pickupDate = self.agreement.rsvpPickupTime
        let formattedDate = dateFormatter.string(from: pickupDate)

        let currentAbbreviation = currentTimeZone.abbreviation(for: pickupDate)
        let apartmentAbbreviation = apartmentTimeZone.abbreviation(for: pickupDate)

        if apartmentAbbreviation != nil && apartmentAbbreviation != currentAbbreviation {
            return "\(formattedDate) \(apartmentAbbreviation!)"
        } else {
            return formattedDate
        }
    }
}

struct TripDetailedInfo: Decodable, Identifiable {
    var id: Agreement.ID { agreement.id }
    let agreement: Agreement
    let vehicle: PublishRenterVehicle
    let apartment: Apartment
    let location: Location
    let vehicleSnapshotBefore: VehicleSnapshot?
    let paymentMethod: PublishPaymentMethod
    let promo: PublishPromo?
    let mileagePackage: MileagePackage?
    let taxes: [Tax]
    let vehicleSnapshotAfter: VehicleSnapshot?
    let rewardTransactions: [RewardTransaction]
}

extension TripDetailedInfo {
    func localizedStartDate() -> String {
        let currentTimeZone = TimeZone.current
        let apartmentTimeZone = TimeZone(identifier: self.apartment.timezone) ?? currentTimeZone

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = apartmentTimeZone
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let pickupDate = self.agreement.rsvpPickupTime
        let formattedDate = dateFormatter.string(from: pickupDate)

        let currentAbbreviation = currentTimeZone.abbreviation(for: pickupDate)
        let apartmentAbbreviation = apartmentTimeZone.abbreviation(for: pickupDate)

        if apartmentAbbreviation != nil && apartmentAbbreviation != currentAbbreviation {
            return "\(formattedDate) \(apartmentAbbreviation!)"
        } else {
            return formattedDate
        }
    }
    func localizedEndDate() -> String {
        let currentTimeZone = TimeZone.current
        let apartmentTimeZone = TimeZone(identifier: self.apartment.timezone) ?? currentTimeZone

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = apartmentTimeZone
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let pickupDate = self.agreement.rsvpDropOffTime
        let formattedDate = dateFormatter.string(from: pickupDate)

        let currentAbbreviation = currentTimeZone.abbreviation(for: pickupDate)
        let apartmentAbbreviation = apartmentTimeZone.abbreviation(for: pickupDate)

        if apartmentAbbreviation != nil && apartmentAbbreviation != currentAbbreviation {
            return "\(formattedDate) \(apartmentAbbreviation!)"
        } else {
            return formattedDate
        }
    }
}
