//
//  LaunchScreenView.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/18/25.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isActive = false

    var body: some View {
        ZStack {
            // 背景颜色铺满屏幕
            Color("MainLoginBG")
                .ignoresSafeArea() // 确保背景覆盖整个屏幕

            VStack {
                Spacer()
                Image("VeygoDraft")  // logo name
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                Spacer()
            }
        }
        .onAppear {
            // 延迟2秒后跳转到登录页面
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    isActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            LoginView()  // 进入登录页
        }
    }
}

#Preview {
    LaunchScreenView()
}
