import SwiftUI

struct AgeView: View {
    @State private var dob: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var goToPhoneView = false

    // 算日期
    private var parsedDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dob)
    }


    // 是否格式对了？
    private var isValidFormat: Bool {
        parsedDate != nil
    }

    // 是否满18岁？包含天数
    private var isOver18: Bool {
        guard let birthDate = parsedDate else { return false }
        let calendar = Calendar.current
        if let eighteenYearsLater = calendar.date(byAdding: .year, value: 18, to: birthDate) {
            return Date() >= eighteenYearsLater
        }
        return false
    }

    private var showDescription: Bool {
        !dob.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Button(action: {
                    dismiss()
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
                        description1: showDescription ? "You must be at least 18 years old to rent from Veygo" : "",
                        description2: ""
                    )
                    .foregroundColor(
                        showDescription
                        ? ((isValidFormat && isOver18) ? Color("Black1") : Color("InvalidRed1"))
                        : Color("Black1")
                    )
                    .padding(.horizontal, 32)

                    Spacer()

                    // 箭头按钮 — 满18岁且格式对了才能启用
                    ArrowButton(isDisabled: !(isValidFormat && isOver18)) {
                        goToPhoneView = true
                        print("Proceed with DOB: \(dob)")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 50)
                }
                .padding(.top, 40)
            }
            .background(Color.white)
            .ignoresSafeArea()
            .navigationDestination(isPresented: $goToPhoneView) {
                PhoneView()
            }
        }
    }
}

#Preview {
    AgeView()
}
