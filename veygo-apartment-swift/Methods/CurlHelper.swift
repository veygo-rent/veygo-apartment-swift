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

class VeygoJsonStandard {
    static let shared = VeygoJsonStandard()
    let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .secondsSince1970
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
//        formatter.locale = Locale(identifier: "en_US_POSIX")
//        formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }()
    let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .secondsSince1970
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
//        formatter.locale = Locale(identifier: "en_US_POSIX")
//        formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        encoder.dateEncodingStrategy = .formatted(formatter)
        return encoder
    }()
}
