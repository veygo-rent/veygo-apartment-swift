//
//  PhoneView.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/19/25.
//

import SwiftUI

struct PhoneView: View {
    @State private var phoneNumber: String = ""
    @State private var descriptions: [(String, Bool)] = [
        ("Phone number has to be in the correct format", false),
        ("Your phone number will be used for communication of important account updates.", false)
    ]
    @Binding var signup: SignupSession
    @Binding var path: NavigationPath

    var body: some View {
        ZStack(alignment: .topLeading) {
            if #unavailable(iOS 26) {
                Button(action: {
                    path.removeLast()
                }) {
                    BackButton()
                }
                .padding(.top, 90)
                .padding(.leading, 30)
            }

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
                ArrowButton(isDisabled: !PhoneNumberValidator(number: phoneNumber).isValidNumber) {
                    signup.phone = PhoneNumberValidator(number: phoneNumber).normalizedNumber
                    path.append(SignupRoute.email)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 50)
            }
            .onChange(of: phoneNumber) { oldValue, newValue in
                let digits = newValue.filter { $0.isNumber }
                var formatted = ""
                if digits.count > 0 { formatted += String(digits.prefix(3)) }
                if digits.count > 3 { formatted += "-" + String(digits.dropFirst(3).prefix(3)) }
                if digits.count > 6 { formatted += "-" + String(digits.dropFirst(6).prefix(4)) }
                phoneNumber = formatted
                descriptions[0].1 = !PhoneNumberValidator(number: formatted).isValidNumber
                descriptions[1].1 = false
            }
            .padding(.top, 40)
        }
        .background(Color("MainBG"))
        .ignoresSafeArea()
        .modifier(BackButtonHiddenModifier())
        .onAppear() {
            if let phone = signup.phone {
                phoneNumber = phone
            }
        }
        .swipeBackGesture {
            path.removeLast()
        }
    }
}

#Preview {
    PhoneView(signup: .init(), path: .constant(.init()))
}
