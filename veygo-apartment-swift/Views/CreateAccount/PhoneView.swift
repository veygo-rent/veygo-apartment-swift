//
//  PhoneView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//

import SwiftUI

struct PhoneView: View {
    @State private var phoneNumber: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var goToEmailView = false

    @State private var descriptions: [(String, Bool)] = [
        ("Phone number has to be in the correct format", false),
        ("Your phone number will be used for communication of important account updates.", false)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                // 返回按钮
                Button(action: {
                    dismiss()
                }) {
                    BackButton()
                }
                .padding(.top, 90)
                .padding(.leading, 30)

                VStack(alignment: .leading, spacing: 20) {
                    Spacer()

                    // 标题
                    LargeTitleText(text: "Get In Touch\nWith Phone")
                        .padding(.bottom, 90)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // 输入框与说明
                    VStack(alignment: .leading, spacing: 5) {
                        InputWithLabel(
                            label: "Your Phone Number",
                            placeholder: "765-273-3727",
                            text: $phoneNumber,
                            descriptions: $descriptions
                        )
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    // 下一步按钮
                    ArrowButton(isDisabled: !isPhoneNumberValid(phoneNumber)) {
                        goToEmailView = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 50)
                }
                .onChange(of: phoneNumber) { oldValue, newValue in
                    descriptions[0].1 = !isPhoneNumberValid(newValue)
                    descriptions[1].1 = false // 始终灰色
                }
                .padding(.top, 40)
            }
            .background(Color("MainBG"))
            .ignoresSafeArea()
            .navigationDestination(isPresented: $goToEmailView) {
                EmailView()
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // 验证手机号码格式
    private func isPhoneNumberValid(_ number: String) -> Bool {
        return number.contains("-") && number.count == 12
    }
}

#Preview {
    PhoneView()
}
