import SwiftUI

struct NameView: View {
    @State private var fullName: String = ""
    @State private var descriptions: [(String, Bool)] = [
        ("You must enter your full name", false),
        ("Your name must match the name appears on your official documents", false)
    ]
    @Binding var signup: SignupSession
    @Binding var path: NavigationPath

    var body: some View {
        ZStack(alignment: .topLeading) {
            if #unavailable(iOS 26) {
                // Conditional for iOS 26
                // Back Button 左上角固定
                Button(action: {
                    signup.date_of_birth = nil
                    signup.phone = nil
                    signup.password = nil
                    signup.name = nil
                    signup.student_email = nil
                    path.removeLast()
                }) {
                    BackButton()
                }
                .padding(.top, 90)
                .padding(.leading, 30)
            }

            VStack(alignment: .leading, spacing: 20) {
                Spacer()

                // Title
                LargeTitleText(text: "Welcome!\nWhat’s Your Name")
                    .padding(.bottom, 90)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Input field without description1
                VStack(alignment: .leading, spacing: 5) {
                    InputWithLabel(
                        label: "Your Full Legal Name",
                        placeholder: "John Appleseed",
                        text: $fullName,
                        descriptions: $descriptions
                    )
                    .onSubmit {
                        let filtered = fullName.filter { $0.isLetter || $0.isWhitespace }
                        let formatted = filtered
                            .split(separator: " ")
                            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
                            .joined(separator: " ")
                        fullName = formatted
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // Arrow Button
                ArrowButton(isDisabled: !(NameValidator(name: fullName).isValidName)) {
                    signup.name = fullName
                    path.append(SignupRoute.age)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 50)
            }
            .onChange(of: fullName) { oldValue, newValue in
                descriptions[0].1 = !(NameValidator(name: fullName).isValidName)
            }
            .padding(.top, 40)
        }
        .background(Color("MainBG"))
        .ignoresSafeArea()
        .modifier(BackButtonHiddenModifier())
        .onAppear() {
            if let name = signup.name {
                fullName = name
            }
        }
        .swipeBackGesture {
            signup.date_of_birth = nil
            signup.phone = nil
            signup.password = nil
            signup.name = nil
            signup.student_email = nil
            path.removeLast()
        }
    }
}
