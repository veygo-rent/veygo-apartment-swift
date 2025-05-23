import SwiftUI

struct AgeValidator {
    let dob: String
    
    var parsedDate: Date? {
        guard dob.count == 10 else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dob)
    }
    
    var isValidFormat: Bool {
        parsedDate != nil
    }
    
    var isOver18: Bool {
        guard let birthDate = parsedDate else { return false }
        let calendar = Calendar.current
        if let eighteenYearsLater = calendar.date(byAdding: .year, value: 18, to: birthDate) {
            return Date() >= eighteenYearsLater
        }
        return false
    }
}

struct AgeView: View {
    @State private var dob: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var goToPhoneView = false
    @State private var descriptions: [(String, Bool)] = [("Your age needs to be in the correct format", false), ("You must be at least 18 years old to rent from Veygo", false)]
    
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
                        descriptions: $descriptions
                    )
                    .padding(.horizontal, 32)
                    .onChange(of: dob) { oldValue, newValue in
                        // Strip non-digits
                        let digits = newValue.filter { $0.isNumber }
                        
                        var formatted = ""
                        for (index, char) in digits.enumerated() {
                            if index == 2 || index == 4 {
                                formatted.append("/")
                            }
                            if index >= 8 { break }
                            formatted.append(char)
                        }
                        
                        // Only update if different to avoid infinite loop
                        if formatted != dob {
                            dob = formatted
                        }
                        let validator = AgeValidator(dob: newValue)
                        descriptions[1].1 = !validator.isOver18
                        descriptions[0].1 = !validator.isValidFormat
                    }
                    
                    Spacer()
                    
                    // 箭头按钮 — 满18岁且格式对了才能启用
                    let validator = AgeValidator(dob: dob)
                    ArrowButton(isDisabled: !validator.isOver18) {
                        goToPhoneView = true
                        print("Proceed with DOB: \(dob)")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 50)
                }
                .padding(.top, 40)
            }
            .background(Color("MainBG"))
            .ignoresSafeArea()
            .navigationDestination(isPresented: $goToPhoneView) {
                PhoneView()
            }
        }.navigationBarBackButtonHidden(true)
    }
}

#Preview {
    AgeView()
}
