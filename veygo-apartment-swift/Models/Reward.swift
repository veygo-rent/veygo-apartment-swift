//
//  Reward.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/1/26.
//

import Foundation

struct RewardTransaction: Identifiable, Equatable, Codable {
    var id: Int
    var agreementId: Int?
    var duration: FlexDecimal
    var transactionTime: Date
    var renterId: Int
}
