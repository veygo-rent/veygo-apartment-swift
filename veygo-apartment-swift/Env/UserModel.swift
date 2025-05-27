//
//  UserModel.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/27/25.
//
import Foundation

struct PublishRenter: Codable, Identifiable {
    let id: Int
    let name: String
    let student_email: String
    let phone: String
    let date_of_birth: String
    let apartment_id: Int
}

// EnvironmentObject
class UserSession: ObservableObject {
    @Published var user: PublishRenter? = nil

    func restoreFromStorage() {
        if let data = UserDefaults.standard.data(forKey: "user"),
           let renter = try? JSONDecoder().decode(PublishRenter.self, from: data) {
            self.user = renter
            print("✅ Restored user from storage: \(renter.name)")
        } else {
            print("⚠️ No saved user found in storage")
        }
    }
}
