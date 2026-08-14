//
//  Errors.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou.
//

import Foundation

enum VeygoError: Error {
    case unauthorized(ErrorResponse)
    case server(status: Int, error: ErrorResponse)
    case decoding
    case network(URLError)
    case unknown

    var display: ErrorResponse {
        switch self {
        case .unauthorized(let e):     return e
        case .server(_, let e):        return e
        case .decoding:                return .E_DECODING
        case .network(let urlError):
            switch urlError.code {
            case .timedOut:               return .E_TIME_OUT
            case .notConnectedToInternet: return .E_NO_INTERNET
            default:                      return .E_DEFAULT
            }
        case .unknown:                 return .E_DEFAULT
        }
    }
}

struct ErrorResponse: Equatable, Codable {
    var title: String
    var message: String
    
    static let E400 = ErrorResponse(title: "Bad Request", message: "The data you provided is not valid.")
    static let E401 = ErrorResponse(title: "Not Authenticated", message: "Please log in again to access this resource.")
    static let E402 = ErrorResponse(title: "Payment Declined", message: "Please try a different card.")
    static let E403 = ErrorResponse(title: "Forbidden", message: "You do not have permission to access this resource.")
    static let E404 = ErrorResponse(title: "Not Found", message: "The content you are trying to access cannot be found.")
    static let E405 = ErrorResponse(title: "Method Not Allowed", message: "The method you have attempted to use is not supported by this endpoint.")
    static let E406 = ErrorResponse(title: "Not Acceptable", message: "The requested format is not supported.")
    static let E409 = ErrorResponse(title: "Conflict", message: "The requested resource already exists.")
    
    static let E500 = ErrorResponse(title: "Internal Server Error", message: "An unexpected error occurred. Please try again later.")
    static let E501 = ErrorResponse(title: "Not Implemented", message: "This feature is not yet available.")
    
    static let E_TIME_OUT = ErrorResponse(title: "Request Timeout", message: "The request timed out. Please try again.")
    static let E_NO_INTERNET = ErrorResponse(title: "No Internet Connection", message: "Please check your internet connection and try again.")
    
    static let E_DECODING = ErrorResponse(title: "Can't Decode Response", message: "Please update your app. This shouldn't have happened.")
    
    static let E_DEFAULT = ErrorResponse(title: "Unknown Error", message: "This shouldn't have happened. Please contact support.")
}
