//
//  HomeView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/27/25.
//
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: UserSession
    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0
    
    @State private var showScanner = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Home Page")
                .font(.largeTitle)
                .foregroundColor(.blue)

            // Debug 输出
            Text("🔑 Token: \(token)")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("🆔 User ID: \(userId)")
                .font(.caption)
                .foregroundColor(.gray)

            if let user = session.user {
                Text("👤 Name: \(user.name)")
                Text("📧 Email: \(user.student_email)")
                Text("📱 Phone: \(user.phone)")
            } else {
                Text("No user loaded.")
                    .foregroundColor(.orange)
            }

            Button("Clear Token") {
                let request = veygoCurlRequest(url: "/api/v1/user/remove-token", method: "GET", headers: ["auth": "\(token)$\(userId)"])
                URLSession.shared.dataTask(with: request) { data, response, error in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        print("Invalid server response.")
                        return
                    }
                    if httpResponse.statusCode == 200 {
                        token = ""
                        userId = 0
                        DispatchQueue.main.async {
                            // Update UserSession
                            self.session.user = nil
                        }
                        print("🧼 Token cleared")
                    }
                }.resume()
            }
            .foregroundColor(.red)
            .padding(.top, 20)
            Button("Scan Card") {
                        showScanner = true
                    }
                    .fullScreenCover(isPresented: $showScanner) {
                        CardScanView { result in
                            switch result {
                            case .completed(let scannedCard):
                                print("Card number: \(scannedCard.pan)")
                            case .canceled:
                                print("Scan canceled")
                            case .failed(let error):
                                print("Scan failed: \(error.localizedDescription)")
                            }
                            showScanner = false
                        }
                    }
        }
        .padding()
        .onAppear {
            print("Entered HomeView")
            print("Token: \(token)")
            print("User ID: \(userId)")
            if let user = session.user {
                print("- Name: \(user.name)")
                print("- Email: \(user.student_email)")
                print("- Phone: \(user.phone)")
            } else {
                print("session.user is nil")
            }
        }
    }
}

#Preview {
    HomeView()
}
