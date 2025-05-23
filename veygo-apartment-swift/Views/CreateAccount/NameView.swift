import SwiftUI

struct NameView: View {
    @State private var fullName: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var goToAgeView = false
    @State private var descriptions: [(String, Bool)] = [
        ("You must enter your full name", false),
        ("Your name must match the name appears on your official documents", false)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                // Back Button 左上角固定
                Button(action: {
                    dismiss()
                }) {
                    BackButton()
                }
                .padding(.top, 90)
                .padding(.leading, 30)

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
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    // Arrow Button
                    ArrowButton(isDisabled: !(fullName.contains(" ") && !fullName.isEmpty)) {
                        goToAgeView = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 50)
                }
                .onChange(of: fullName) { oldValue, newValue in
                    descriptions[0].1 = !(newValue.contains(" ") && !newValue.isEmpty)
                }
                .padding(.top, 40)
            }
            .background(Color("MainBG"))
            .ignoresSafeArea()
            .navigationDestination(isPresented: $goToAgeView) {
                AgeView()
            }
        }.navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NameView()
}
