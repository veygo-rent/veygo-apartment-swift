//
//  MileagePackage.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/12/26.
//

import Foundation

struct MileagePackage: Identifiable, Equatable, Decodable, Hashable {
    var id: Int
    var miles: Int
    var discountedRate: Int
    var isActive: Bool
}

struct NewMileagePackage: Equatable, Encodable {
    var miles: Int
    var discountedRate: Int
    var isActive: Bool
}
