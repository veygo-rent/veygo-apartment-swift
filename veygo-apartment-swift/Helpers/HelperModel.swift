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

nonisolated struct CurrentTrip: Codable {
    let agreement: Agreement
    let vehicle: PublishRenterVehicle
    let apartment: Apartment
    let location: Location
    let vehicleSnapsahotBefore: VehicleSnapshot?
    let paymentMethod: PublishPaymentMethod
    let promo: PublishPromo?
    let mileagePackage: MileagePackage?
}
