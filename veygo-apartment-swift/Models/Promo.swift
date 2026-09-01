//
//  Promo.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/1/26.
//

import Foundation

struct PublishPromo: Identifiable, Equatable, Codable, HasName {
    var id: String { code }
    var code: String
    var name: String
    var amount: FlexDecimal
    var isEnabled: Bool
    var isOneTime: Bool
    var exp: Date
}
