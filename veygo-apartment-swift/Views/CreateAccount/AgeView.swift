import SwiftUI

struct AgeView: View {
    @State private var dob: String = ""
    @State private var descriptions: [(String, Bool)] = [("Your age needs to be in the correct format", false), ("You must be at least 18 years old to rent from Veygo", false)]
    @ObservedObject var signup: SignupSession
    @Binding var path: NavigationPath

    var body: some View {
        ZStack(alignment: .topLeading) {
            EnableSwipeBackGesture() 
            Button(action: {
                path.removeLast()
            }) {
                BackButton()
            }
            .padding(.top, 90)
            .padding(.leading, 30)

            VStack(alignment: .leading, spacing: 20) {
                Spacer()

                // 标题
                LargeTitleText(text: "Next Up,\nHow Old Are You?")
                    .padding(.bottom, 90)
                    .frame(maxWidth: .infinity, alignment: .center)

                // 输入框和描述
                InputWithLabel(
                    label: "Date of Birth",
                    placeholder: "MM/DD/YYYY",
                    text: $dob,
                    descriptions: $descriptions
                )
                .padding(.horizontal, 32)
                .onChange(of: dob) { oldValue, newValue in
                    let digits = newValue.filter { $0.isNumber }
                    var formatted = ""
                    for (index, char) in digits.enumerated() {
                        if index == 2 || index == 4 {
                            formatted.append("/")
                        }
                        if index >= 8 { break }
                        formatted.append(char)
                    }
                    if formatted != dob {
                        dob = formatted
                    }
                    let validator = AgeValidator(dob: newValue)
                    descriptions[1].1 = !validator.isOver18
                    descriptions[0].1 = !validator.isValidFormat
                }

                Spacer()

                // 箭头按钮 — 满18岁且格式对了才能启用
                let validator = AgeValidator(dob: dob)
                ArrowButton(isDisabled: !validator.isOver18) {
                    signup.date_of_birth = dob
                    path.append(SignupRoute.phone)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 50)
            }
            .padding(.top, 40)
        }
        .background(Color("MainBG"))
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let age = signup.date_of_birth {
                dob = age
            }
        }
    }
}

#Preview {
    AgeView(signup: .init(), path: .constant(.init()))
}
