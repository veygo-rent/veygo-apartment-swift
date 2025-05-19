//
//  NameView.swift
//  veygo-apartment-swift
//
//  Created by Sardine on 5/19/25.
//

//import SwiftUI
//
//struct NameView: View {
//    @State private var fullName: String = ""
//
//    var body: some View {
//        VStack(spacing: 40) {
//            // 顶部大字
//            LargeTitleText(text: "Welcome!\nWhat's Your Name")
//
//            // 输入框区域
//            InputWithLabel(
//                label: "Your Full Legal Name",
//                placeholder: "Xinyi Guan",
//                text: $fullName,
//                description1: "You must enter your full name",
//                description2: "Your name must match the name appears on your official documents"
//            )
//
//            // 底部箭头按钮
//            ArrowButton {
//                print("Proceed with Name: \(fullName)")
//            }
//
//            Spacer()
//        }
//        .padding()
//        .background(Color.white)
//        .ignoresSafeArea()
//    }
//}
//
//#Preview {
//    NameView()
//}
//
