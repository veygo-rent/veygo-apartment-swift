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
}

