//
//  ContactView.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/7/25.
//

import SwiftUI

struct ContactView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(spacing: 30) {
            BannerView(
                           showBackButton: true,
                           onBack: { dismiss() }
                       )
                .ignoresSafeArea(.container, edges: .top)
            
            Text("You can get in touch with us through these methods. Our team will reach out to you as soon as possible.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color("FootNote"))
                .padding(.horizontal, 24)

            ContactInfoPanel(phone: "+1 (765) 273-3727", email: "info@veygo.rent")
            SocialMediaPanel(Instagram:"info@veygo.rent", X: "info@veygo.rent", Facebook: "info@veygo.rent")

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ContactView()
}
