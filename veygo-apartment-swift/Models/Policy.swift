//
//  Policy.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/13/26.
//

import Foundation

struct Policy: Identifiable, Equatable, Decodable {
    var id: Int
    var policyType: PolicyType
    var policyEffectiveDate: String
    var content: String
}
