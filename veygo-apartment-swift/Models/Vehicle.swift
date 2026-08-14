//
//  Vehicle.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/12/26.
//

import Foundation

struct PublishRenterVehicle: Identifiable, Equatable, Codable, Hashable {
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
