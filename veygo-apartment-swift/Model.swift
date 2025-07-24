//
//  UserModel.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/27/25.
//

import SwiftUI
import MapKit

enum VerificationType: String, Codable {
    case email = "Email"
    case phone = "Phone"
}

enum AgreementStatus: String, Codable {
    case rental = "Rental"
    case void = "Void"
    case canceled = "Canceled"
}

enum EmployeeTier: String, Codable {
    case user = "User"
    case generalEmployee = "GeneralEmployee"
    case maintenance = "Maintenance"
    case admin = "Admin"
}

enum PaymentType: String, Codable {
    case canceled = "canceled"
    case processing = "processing"
    case requiresAction = "requires_action"
    case requiresCapture = "requires_capture"
    case requiresConfirmation = "requires_confirmation"
    case requiresPaymentMethod = "requires_payment_method"
    case succeeded = "succeeded"
}

enum PlanTier: String, Codable {
    case free = "Free"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
}

enum Gender: String, Codable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case pnts = "PNTS"
}

enum TransactionType: String, Codable {
    case credit = "Credit"
    case cash = "Cash"
}

struct PublishRenter: Codable, Identifiable, Equatable {
    var id: Int
    var name: String
    var studentEmail: String
    var studentEmailExpiration: String?
    var phone: String
    var phoneIsVerified: Bool
    var dateOfBirth: String
    var profilePicture: String?
    var gender: Gender?
    var dateOfRegistration: Date
    var driversLicenseNumber: String?
    var driversLicenseStateRegion: String?
    var driversLicenseExpiration: Date?
    var insuranceLiabilityExpiration: Date?
    var insuranceCollisionExpiration: Date?
    var apartmentId: Int
    var leaseAgreementExpiration: Date?
    var billingAddress: String?
    var signatureDatetime: Date?
    var planTier: PlanTier
    var planRenewalDay: String
    var planExpireMonthYear: String
    var planAvailableDuration: Double
    var isPlanAnnual: Bool
    var employeeTier: EmployeeTier
    var subscriptionPaymentMethodId: Int?
}


struct Apartment: Identifiable, Equatable, Codable {
    var id: Int
    var name: String
    var email: String
    var phone: String
    var address: String
    var acceptedSchoolEmailDomain: String
    var freeTierHours: Double
    var freeTierRate: Double
    var silverTierHours: Double
    var silverTierRate: Double
    var goldTierHours: Double
    var goldTierRate: Double
    var platinumTierHours: Double
    var platinumTierRate: Double
    var durationRate: Double
    var liabilityProtectionRate: Double
    var pcdwProtectionRate: Double
    var pcdwExtProtectionRate: Double
    var rsaProtectionRate: Double
    var paiProtectionRate: Double
    var isOperating: Bool
    var isPublic: Bool
    var uniId: Int
    var taxes: [Int?]
}

class SignupSession: ObservableObject {
    @Published var name: Optional<String> = nil
    @Published var date_of_birth: Optional<String> = nil  // MM/DD/YYYY
    @Published var phone: Optional<String> = nil
    @Published var student_email: Optional<String> = nil
    @Published var password: Optional<String> = nil
}

struct Car: Identifiable {
    let id = UUID()
    var location: String
    var timeText: String
    var name: String
    var price: String
    var features: [String]
    var imageName: String
    var iconName: String // 小人图标
}

struct PublishPaymentMethod: Identifiable, Codable, Equatable {
    let id: Int
    let cardholderName: String
    let maskedCardNumber: String
    let network: String
    let expiration: String
    let md5: String
    let nickname: String?
    let isEnabled: Bool
    let renterID: Int
    let lastUsedDateTime: String?
}

struct CarLocation: Identifiable, Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let cars: [Car]

    static func == (lhs: CarLocation, rhs: CarLocation) -> Bool {
        return lhs.id == rhs.id
    }
}

class UserSession: ObservableObject {
    @Published var user: PublishRenter? = nil
    
    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0

    // 用 token 和 user_id 调用后端 API 验证并查找用户信息 对了—>200, 不对—>re-login
    func validateTokenAndFetchUser(completion: @escaping (Bool) -> Void) {
        let request = veygoCurlRequest(url: "/api/v1/user/retrieve", method: "GET", headers: ["auth": "\(token)$\(userId)"])
        
        if (token == "" || userId == 0) {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let data = data else {
                print("Invalid or unauthorized response")
                completion(false)
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let renter = json["renter"],
               let renterData = try? JSONSerialization.data(withJSONObject: renter),
               let decodedUser = try? VeygoJsonStandard.shared.decoder.decode(PublishRenter.self, from: renterData) {
                let newToken: String = httpResponse.value(forHTTPHeaderField: "token")!
                DispatchQueue.main.async {
                    self.user = decodedUser
                    self.token = newToken
                    self.userId = decodedUser.id
                }
                print("New token refreshed.")
                print("User loaded via token: \(decodedUser.name)")
                completion(true)
            } else {
                print("Failed to parse user from response")
                completion(false)
            }
        }.resume()
    }
    
    func clear() {
        self.user = nil
        self.token = ""
        self.userId = 0
    }
    
}
