import SwiftUI

struct InputWithLabel: View {
    let label: Optional<String>
    let placeholder: String
    var alignment: TextAlignment = .leading
    var isSecure: Bool = false
    @Binding var text: String
    @Binding var descriptions: [(String, Bool)]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let label = label {
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(Color("TextBlackPrimary"))
            }

            TextInputField(placeholder: placeholder, text: $text, isSecure: isSecure)
                .multilineTextAlignment(alignment)

            ForEach(descriptions, id: \.0) { item in
                Text(item.0)
                    .font(.system(size: 12, weight: !item.1 ? .light : .regular, design: .default))
                    .foregroundColor(
                        !item.1
                        ? Color("TextBlackSecondary")
                        : Color("InvalidRed")
                    )
            }
        }
    }
}
