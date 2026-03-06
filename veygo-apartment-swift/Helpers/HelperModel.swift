//
//  HelperStrusts.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/19/25.
//

import Foundation

/// Reservation Helper Structs...
nonisolated struct BlockedRange: Decodable, Hashable {
    var startTime: Date
    var endTime: Date
}

nonisolated struct VehicleWithBlockedDurations: Decodable, Identifiable, Equatable, Hashable {
    static func == (lhs: VehicleWithBlockedDurations, rhs: VehicleWithBlockedDurations) -> Bool {
        lhs.id == rhs.id
    }
    
    var vehicle: PublishRenterVehicle
    var blockedDurations: [BlockedRange]
    var id: PublishRenterVehicle.ID { vehicle.id }

    func isVehicleAvailable(start startTime: Date, end endTime: Date) -> Bool {
        for blocked in blockedDurations {
            if startTime < blocked.endTime && endTime > blocked.startTime {
                return false
            }
        }
        return true
    }
}

nonisolated struct LocationWithVehicles: Decodable, Identifiable {
    var location: Location
    var vehicles: [VehicleWithBlockedDurations]
    var id: Location.ID { location.id }
    var duration: TimeInterval? = nil
}

nonisolated struct TripInfo: Codable, Identifiable {
    var id: Agreement.ID { agreement.id }
    let agreement: Agreement
    let apartmentTimezone: String
    let locationName: String
    let vehicleName: String
}

nonisolated struct TripDetailedInfo: Codable, Identifiable {
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
}

nonisolated struct FilePath: Codable {
    let filePath: String
}

nonisolated struct GenerateSnapshotRequest: Codable {
    let vehicleVin: String
    let leftImagePath: String
    let rightImagePath: String
    let frontImagePath: String
    let backImagePath: String
    let frontRightImagePath: String
    let frontLeftImagePath: String
    let backRightImagePath: String
    let backLeftImagePath: String
}

nonisolated struct CheckOutRequest: Codable {
    let agreementId: Agreement.ID
    let vehicleSnapshotId: VehicleSnapshot.ID
    let hoursUsingReward: Int
}
