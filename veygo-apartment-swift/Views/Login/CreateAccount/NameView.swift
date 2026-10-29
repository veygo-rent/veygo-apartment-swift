import SwiftUI

struct NameView: View {
    @FocusState private var fieldIsFocused: Bool
    @State private var fullName: String = ""
    @State private var descriptions: [(String, Bool)] = [
        ("You must enter your full name", false),
        ("Your name must match the name appears on your official documents", false)
    ]
    @State private var signup: NewRenter = NewRenter()
    @Binding var path: NavigationPath

    var body: some View {
        ZStack(alignment: .topLeading) {

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
                    .focused($fieldIsFocused)
                    .sensoryFeedback(.selection, trigger: fieldIsFocused)
                    .textInputAutocapitalization(.words)
                    .textContentType(.name)
                    .onChange(of: fieldIsFocused) { old, _ in
                        if old {
                            fullName = VeygoNameStandard.format(name: fullName)
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // Arrow Button
                ArrowButton(isDisabled: !(NameValidator(name: fullName).isValidName)) {
                    signup.name = fullName
                    path.append(SignupRoute.age(renterInfo: signup))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 50)
            }
            .onChange(of: fullName) { oldValue, newValue in
                descriptions[0].1 = !(NameValidator(name: fullName).isValidName)
            }
            .padding(.top, 40)
        }
        .background(Color.mainBG)
        .ignoresSafeArea()
        .onAppear() {
            if let name = signup.name {
                fullName = name
            }
        }
        .onTapGesture {
            fullName = VeygoNameStandard.format(name: fullName)
            fieldIsFocused = false
        }
    }
}
