//
//  Vehicle.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/12/26.
//

import Foundation

struct PublishRenterVehicle: Identifiable, Equatable, Decodable, Hashable {
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
    var msrpFactor: FlexDecimal
    var imageLink: String?
    var odometer: Int
    var tankSize: FlexDecimal
    var tankLevelPercentage: Int
    var locationId: Int
    var remoteMgmt: RemoteMgmtType
    var requiresOwnInsurance: Bool
}

struct VehicleSnapshot: Identifiable, Equatable, Decodable {
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

struct BlockedRange: Decodable, Hashable {
    var startTime: Date
    var endTime: Date
}

struct VehicleWithBlockedDurations: Decodable, Identifiable, Equatable, Hashable {
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
