//
//  HubView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//
import SwiftUI

struct HubView: View {
    @State private var email: String = ""
    @State private var code: String = ""
    @State private var goToCongrats = false
    @State private var isCodeValid = false

    @State private var codeDescriptions: [(String, Bool)] = []

    let allowedDomains = ["purdue.edu", "iu.edu"]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                // Back button
                Button(action: {
                    // 返回逻辑
                }) {
                    BackButton()
                }
                .padding(.top, 90)
                .padding(.leading, 30)

                VStack(alignment: .leading, spacing: 20) {
                    Spacer()

                    // Title
                    LargeTitleText(text: "Let’s Find Your\nVeygo Hub")
                        .padding(.bottom, 60)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // Email input
                    VStack(alignment: .leading, spacing: 5) {
                        InputWithLabel(
                            label: "Your University Email",
                            placeholder: "Email",
                            text: $email,
                            descriptions: .constant([]) // 无提示
                        )
                    }
                    .padding(.horizontal, 32)

                    // Code input with red warning
                    VStack(alignment: .leading, spacing: 5) {
                        InputWithLabel(
                            label: "Verification Code",
                            placeholder: "- - - - - -",
                            alignment: .center,
                            text: $code,
                            descriptions: $codeDescriptions
                        )
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    // Arrow Button
                    ArrowButton(isDisabled: !isCodeValid) {
                        goToCongrats = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 60)
                }
                .padding(.top, 40)
                .onChange(of: email) { _, newValue in
                    let lowercased = newValue.lowercased()
                    if lowercased.isEmpty {
                        codeDescriptions = []
                        return
                    }
                    if let domain = lowercased.split(separator: "@").last {
                        if !allowedDomains.contains(String(domain)) {
                            codeDescriptions = [("Sorry! We currently don’t serve that campus.", true)]
                        } else {
                            codeDescriptions = []
                        }
                    } else {
                        codeDescriptions = [("Sorry! We currently don’t serve that campus.", true)]
                    }
                }
                .onChange(of: code) { _, newValue in
                    // 这里用一个假的验证码 “123456” 作为模拟
                    isCodeValid = (newValue == "123456")
                }
            }
            .background(Color("MainBG"))
            .ignoresSafeArea()
            .navigationDestination(isPresented: $goToCongrats) {
                CongratsView()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    HubView()
}
