import SwiftUI

struct PrimaryButton: View {
    // 接收按钮文本和点击事件
    let text: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .font(.system(size: 17, weight: .semibold, design: .default))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .tint(Color("PrimaryButtonBg"))
        .frame(height: 45)
    }
}

#Preview {
    PrimaryButton(text: "Login") {
        print("Log In Button Pressed")
    }
}
