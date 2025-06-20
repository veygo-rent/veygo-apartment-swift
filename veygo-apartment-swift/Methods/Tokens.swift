//
//  Tokens.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 6/20/25.
//

import Foundation

func extractToken(from response: URLResponse?) -> String? {
    guard let httpResponse = response as? HTTPURLResponse else {
        print("Failed to cast response to HTTPURLResponse")
        return nil
    }
    let token = httpResponse.value(forHTTPHeaderField: "token")
    print("Extracted token from header: \(token ?? "nil")")
    return token
}
