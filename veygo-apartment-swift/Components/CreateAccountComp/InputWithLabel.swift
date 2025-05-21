import SwiftUI

struct InputWithLabel: View {
    let label: Optional<String>
    let placeholder: String
    @Binding var text: String
    @Binding var descriptions: [(String, Bool)]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let label = label {
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(Color("Black1"))
            }

            TextInputField(placeholder: placeholder, text: $text)

            ForEach(descriptions, id: \.0) { item in
                Text(item.0)
                    .font(.system(size: 12, weight: !item.1 ? .light : .regular, design: .default))
                    .foregroundColor(
                        !item.1
                        ? Color("Black1")
                        : Color("InvalidRed1")
                    )
            }
        }
    }
}
