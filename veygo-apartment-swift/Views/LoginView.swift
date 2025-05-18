//
//  LoginView.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/18/25.
//

import SwiftUI

struct LoginView: View {
    var body: some View {
        VStack {
            Text("Login Page")
                .font(.largeTitle)
                .padding()
            Text("This is a placeholder for the login screen.")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    LoginView()
}
