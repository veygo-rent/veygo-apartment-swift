import SwiftUI

struct AgeView: View {
    @State private var dob: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var goToPhoneView = false
    @State private var descriptions: [(String, Bool)] = [("Your age needs to be in the correct format", false), ("You must be at least 18 years old to rent from Veygo", false)]
    @EnvironmentObject var signup: SignupSession
    
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
                        signup.date_of_birth = dob
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
