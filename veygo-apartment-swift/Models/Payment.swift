//
//  Payment.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/1/26.
//

import Foundation

struct PublishPaymentMethod: Identifiable, Equatable, Decodable {
    var id: Int
    var cardholderName: String
    var maskedCardNumber: String
    var network: String
    var expiration: String
    var nickname: String?
    var isEnabled: Bool
    var renterId: Int
    var lastUsedDateTime: Date?
    var cdwEnabled: Bool
}
