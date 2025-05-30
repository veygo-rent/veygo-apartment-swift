//
//  UserModel.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/27/25.
//

import Foundation
import SwiftUI


struct PublishRenter: Codable, Identifiable {
    let id: Int
    let name: String
    let student_email: String
    let phone: String
    let date_of_birth: String
    let apartment_id: Int
}

class SignupSession: ObservableObject {
    @Published var name: String = ""
    @Published var date_of_birth: String = ""  // MM/DD/YYYY
    @Published var phone: String = ""
    @Published var student_email: String = ""
    @Published var password: String = ""
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
               let decodedUser = try? JSONDecoder().decode(PublishRenter.self, from: renterData) {
                let newToken: String = httpResponse.value(forHTTPHeaderField: "token")!
                DispatchQueue.main.async {
                    self.user = decodedUser
                }
                UserDefaults.standard.set(newToken, forKey: "token")
                UserDefaults.standard.set(decodedUser.id, forKey: "user_id")
                print("New token refreshed.")
                print("User loaded via token: \(decodedUser.name)")
                completion(true)
            } else {
                print("Failed to parse user from response")
                completion(false)
            }
        }.resume()
    }
}
