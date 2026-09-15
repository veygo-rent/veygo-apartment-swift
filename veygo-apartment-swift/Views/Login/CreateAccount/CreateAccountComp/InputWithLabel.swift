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
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.textBlackPrimary)
            }

            TextInputField(text: $text, placeholder: placeholder, isSecure: isSecure)
                .multilineTextAlignment(alignment)

            ForEach(descriptions, id: \.0) { item in
                Text(item.0)
                    .font(.subheadline)
                    .fontWeight(!item.1 ? .light : .regular)
                    .foregroundColor(
                        !item.1
                        ? Color.textBlackSecondary
                        : Color.invalidRed
                    )
            }
        }
    }
}
