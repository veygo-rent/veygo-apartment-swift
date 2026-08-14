//
//  CongratsView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//
import SwiftUI

struct CongratsView: View {
    @Environment(Session.self) private var session
    
    let user: RegisteredRenter
    
    var body: some View {
        VStack {
            Text("Yey Page")
                .font(.largeTitle)
                .foregroundColor(.blue)
            ArrowButton() {
                session.login(token: user.token, userId: user.renter.id, renter: user.renter)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 50)
        }
        .navigationBarBackButtonHidden(true)
    }
}
