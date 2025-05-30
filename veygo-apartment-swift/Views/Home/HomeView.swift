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
                token = ""
                userId = 0
                session.user = nil
                print("🧼 Token cleared")
            }
            .foregroundColor(.red)
            .padding(.top, 20)
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
