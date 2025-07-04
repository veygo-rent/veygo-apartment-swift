//
//  Banner.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/4/25.
//

import SwiftUI

struct BannerView: View {
    var body: some View {
        Rectangle()
            .fill(Color("Accent2Color").opacity(0.6))
            .frame(height: 90)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    BannerView()
}
