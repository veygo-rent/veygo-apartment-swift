//
//  CongratsView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//
import SwiftUI

struct CongratsView: View {
    @Binding var user: Optional<PublishRenter>
    @EnvironmentObject var session: UserSession
    var body: some View {
        VStack {
            Text("Yey Page")
                .font(.largeTitle)
                .foregroundColor(.blue)
            ArrowButton(isDisabled: user == nil) {
                session.user = user
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 50)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    CongratsView(user: .constant(nil))
}

