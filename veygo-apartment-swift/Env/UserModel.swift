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

class UserSession: ObservableObject {
    @Published var user: PublishRenter? = nil

    /// 读取用户信息
    func restoreUserFromDisk() {
        if let data = UserDefaults.standard.data(forKey: "user"),
           let decoded = try? JSONDecoder().decode(PublishRenter.self, from: data) {
            self.user = decoded
            print("Restored user from disk: \(decoded.name)")
        } else {
            print("Failed to restore user from disk")
        }
    }

    /// 用 token 和 user_id 调用后端 API 验证并刷新用户信息
    func validateTokenAndFetchUser(token: String, userId: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://dev.veygo.rent/api/v1/user/retrieve") else {
            print("Invalid /user/retrieve URL")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "token")
        request.setValue(String(userId), forHTTPHeaderField: "user_id")

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

                let newToken = httpResponse.value(forHTTPHeaderField: "token")

                DispatchQueue.main.async {
                    self.user = decodedUser
                    UserDefaults.standard.set(try? JSONEncoder().encode(decodedUser), forKey: "user")
                    if let newToken = newToken {
                        UserDefaults.standard.set(newToken, forKey: "token")
                        print("New token refreshed.")
                    }
                    print("User loaded via token: \(decodedUser.name)")
                    completion(true)
                }
            } else {
                print("Failed to parse user from response")
                completion(false)
            }
        }.resume()
    }
}
