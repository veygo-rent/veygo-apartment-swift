//
//  CurlHelper.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 5/29/25.
//

import Foundation

public func veygoCurlRequest (url: String, method: String, headers: [String: String] = [:], body: Data? = nil) -> URLRequest {
    let BASE_PATH = "https://dev.veygo.rent"
    guard let fullURL = URL(string: "\(BASE_PATH)\(url)") else {
        fatalError("Invalid URL: \(BASE_PATH)\(url)")
    }

    var request = URLRequest(url: fullURL)
    request.httpMethod = method
    request.allHTTPHeaderFields = headers
    request.httpBody = body
    
    if headers["Content-Type"] == nil && method != "GET" {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    request.setValue("none", forHTTPHeaderField: "Debug-Mode")
    #if DEBUG
    request.setValue("ios", forHTTPHeaderField: "Debug-Mode")
    #endif

    return request
}

class VeygoDecoderStandard {
    static let shared = VeygoDecoderStandard()
    let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
