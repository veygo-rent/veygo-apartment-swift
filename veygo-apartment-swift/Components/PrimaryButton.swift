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
                .foregroundColor(Color("PrimaryButtonText"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .tint(Color("PrimaryButtonBg"))
        .frame(height: 45)
        .shadow(color: Color("ShadowPrimary").opacity(0.5), radius: 3, x: 2, y: 4)
    }
}

#Preview {
    PrimaryButton(text: "Login") {
        print("Log In Button Pressed")
    }
}
