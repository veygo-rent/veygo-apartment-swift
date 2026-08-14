//
//  UsAddress.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/12/26.
//

import Foundation

struct UsAddress: Equatable, Codable, Hashable {
    var streetAddress: String
    var extendedAddress: String?
    var city: String
    var state: String
    var zipcode: String
}
