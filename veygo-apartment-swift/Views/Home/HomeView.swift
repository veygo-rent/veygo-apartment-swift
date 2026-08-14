//
//  HomeView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/12/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(Session.self) private var session
    var body: some View {
        Text("Hello, World!")
            .onTapGesture {
                session.clear()
            }
    }
}
