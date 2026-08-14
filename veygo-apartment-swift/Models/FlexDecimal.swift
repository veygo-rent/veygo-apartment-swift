//
//  FlexDecimal.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/12/26.
//

import Foundation

struct FlexDecimal: Codable, Equatable, Hashable, Sendable {
    let value: Decimal

    init(_ value: Decimal) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self),
           let decimal = Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")) {
            self.value = decimal
            return
        }

        if let decimal = try? container.decode(Decimal.self) {
            self.value = decimal
            return
        }

        if let int = try? container.decode(Int.self) {
            self.value = Decimal(int)
            return
        }

        if let double = try? container.decode(Double.self) {
            self.value = Decimal(double)
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Expected decimal as string or number"
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(NSDecimalNumber(decimal: value).stringValue)
    }
}
