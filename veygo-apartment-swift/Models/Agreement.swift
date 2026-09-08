//
//  Agreement.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/1/26.
//

import Foundation

struct RateOffer: Identifiable, Equatable, Decodable, Hashable {
    var id: Int
    var renterId: Int
    var apartmentId: Int
    var multiplier: FlexDecimal
    var exp: Date
}

struct Agreement: Identifiable, Equatable, Decodable {
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

struct TripInfo: Decodable, Identifiable {
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

enum CheckInOutRequest: Encodable {
    case withSnapshotId(agreementId: Agreement.ID, vehicleSnapshotId: VehicleSnapshot.ID)
    case withImagePath(
        agreementId: Agreement.ID,
        leftImagePath: String,
        rightImagePath: String,
        frontImagePath: String,
        backImagePath: String,
        frontRightImagePath: String,
        frontLeftImagePath: String,
        backLeftImagePath: String,
        backRightImagePath: String
    )

    private enum CodingKeys: String, CodingKey {
        case type
        case agreementId
        case vehicleSnapshotId
        case leftImagePath
        case rightImagePath
        case frontImagePath
        case backImagePath
        case frontRightImagePath
        case frontLeftImagePath
        case backLeftImagePath
        case backRightImagePath
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .withSnapshotId(agreementId, vehicleSnapshotId):
            try container.encode("with_snapshot_id", forKey: .type)
            try container.encode(agreementId, forKey: .agreementId)
            try container.encode(vehicleSnapshotId, forKey: .vehicleSnapshotId)
        case let .withImagePath(
            agreementId,
            leftImagePath,
            rightImagePath,
            frontImagePath,
            backImagePath,
            frontRightImagePath,
            frontLeftImagePath,
            backLeftImagePath,
            backRightImagePath
        ):
            try container.encode("with_image_path", forKey: .type)
            try container.encode(agreementId, forKey: .agreementId)
            try container.encode(leftImagePath, forKey: .leftImagePath)
            try container.encode(rightImagePath, forKey: .rightImagePath)
            try container.encode(frontImagePath, forKey: .frontImagePath)
            try container.encode(backImagePath, forKey: .backImagePath)
            try container.encode(frontRightImagePath, forKey: .frontRightImagePath)
            try container.encode(frontLeftImagePath, forKey: .frontLeftImagePath)
            try container.encode(backLeftImagePath, forKey: .backLeftImagePath)
            try container.encode(backRightImagePath, forKey: .backRightImagePath)
        }
    }
}
