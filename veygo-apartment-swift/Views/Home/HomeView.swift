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
    
    var body: some View {
        VStack {
            Text("Home Page")
                .font(.largeTitle)
                .foregroundColor(.blue)
                .onAppear {
                    print("User entered HomeView.")
                }

            Button("Clear Token") {
                token = ""               // 清除 AppStorage 中的 token
                session.user = nil       // 清除内存中的 user
                print("Token cleared")
            }
            .foregroundColor(.red)
            .padding(.top, 20)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(UserSession())
}
