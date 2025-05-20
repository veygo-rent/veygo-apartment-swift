import SwiftUI

struct InputWithLabel: View {
    var label: String
    var placeholder: String
    @Binding var text: String
    var description1: String
    var description2: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .default))
                .foregroundColor(Color("Black1"))

            TextInputField(placeholder: placeholder, text: $text)

            if !description1.isEmpty {
                Text(description1)
                    .font(.system(size: 12, weight: .light, design: .default))
            }

            if !description2.isEmpty {
                Text(description2)
                    .font(.system(size: 12, weight: .light, design: .default))
            }
        }
    }
}
