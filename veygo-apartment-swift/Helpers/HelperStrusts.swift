//
//  HelperStrusts.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/19/25.
//

import Foundation

/// Reservation Helper Structs...
nonisolated struct BlockedRange: Decodable {
    var startTime: Date
    var endTime: Date
}
nonisolated struct VehicleWithBlockedDurations: Decodable, Identifiable {
    var vehicle: PublishVehicle
    var blockedDurations: [BlockedRange]
    var id: PublishVehicle.ID { vehicle.id }
}
nonisolated struct LocationWithVehicles: Decodable, Identifiable {
    var location: Location
    var vehicles: [VehicleWithBlockedDurations]
    var id: Location.ID { location.id }
    var duration: TimeInterval? = nil
}
