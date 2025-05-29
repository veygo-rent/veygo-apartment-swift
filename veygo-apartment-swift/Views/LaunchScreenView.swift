//
//  LaunchScreenView.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/18/25.
//

import SwiftUI

struct LaunchScreenView: View {
    @EnvironmentObject var session: UserSession
    @State private var isActive = false
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0 
    
    var body: some View {
        VStack {
            Spacer()
            Image("VeygoLogo")  // logo name
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
                .offset(y: -50)  // 上移50个单位
                .scaleEffect(scale)  // 缩放效果
                .opacity(opacity)    // 透明度效果
                .animation(.easeInOut(duration: 2), value: scale)  // 动画效果
                .animation(.easeInOut(duration: 2), value: opacity)
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2)) {
                scale = 1.2
                opacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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
