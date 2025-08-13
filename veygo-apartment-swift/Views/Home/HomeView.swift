import SwiftUI
import UserNotifications

enum HomeDestination: Hashable {
    case university
    case apartment
}

private func roundUpToNextQuarter(from date: Date) -> Date {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    guard let hour = components.hour, let minute = components.minute else { return date }
    let quarter = ((minute / 15) + 1) * 15
    let newHour = hour + (quarter / 60)
    let newMinute = quarter % 60
    return calendar.date(from: DateComponents(year: components.year, month: components.month, day: components.day, hour: newHour, minute: newMinute)) ?? date
}

struct HomeView: View {
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @EnvironmentObject var session: UserSession
    
    @AppStorage("apns_token") var apns_token: String = ""
    
    @State private var selectedToggle: RentalOption = .university
    @State private var selectedLocation: Apartment.ID? = nil
    
    @State private var startDate: Date = {
        let start = Date().addingTimeInterval(1800)
        return roundUpToNextQuarter(from: start)
    }()
    @State private var endDate: Date = {
        let end = Date().addingTimeInterval(3600)
        return roundUpToNextQuarter(from: end)
    }()
    
    @State private var promoCode: String = ""
    @Binding var universities: [Apartment]
    
    @State private var path: [HomeDestination] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                
                VStack(alignment: .leading, spacing: 16) {
                    // Make a Reservation & others
                    Title(text: "Make a Reservation", fontSize: 20, color: Color("TextBlackPrimary"))
                        .padding(.horizontal, 24)
                    SlidingToggleButton(selectedOption: $selectedToggle)
                        .padding(.horizontal, 24)
                    Dropdown(
                        selectedOption: $selectedLocation,
                        labelText: .constant("Rental location"),
                        universityOptions: $universities
                    )
                    .padding(.horizontal, 24)
                    DatePanel(startDate: $startDate, endDate: $endDate, isEditMode: true)
                        .padding(.horizontal, 24)
                    
                    // Promo code + Apply
                    HStack(spacing: 16) {
                        InputWithInlinePrompt(promptText: "Promo code / coupon", userInput: $promoCode)
                            .onChange(of: promoCode) { old, newValue in
                                var result = ""
                                var previousWasDash = false
                                for (_, char) in newValue.enumerated() {
                                    if char.isLetter || char.isNumber {
                                        result.append(char)
                                        previousWasDash = false
                                    } else if char == "-" && !previousWasDash && !result.isEmpty {
                                        result.append(char)
                                        previousWasDash = true
                                    }
                                    // skip if it's a dash and previousWasDash is true, or if would be the first character
                                }
                                let finalResult = result.uppercased()
                                if promoCode != finalResult {
                                    promoCode = finalResult
                                }
                            }
                        
                        SecondaryButtonLg(text: "Apply") {
                            if !promoCode.isEmpty {
                                print("Apply tapped with promo code: \(promoCode)")
                            } else {
                                
                            }
                        }
                        .frame(width: 92)
                    }
                    .padding(.horizontal, 24)
                    
                    PrimaryButtonLg(text: "Vehicle Look Up") {
                        if selectedLocation != nil {
                            path.append(.university)
                        }
                    }
                    .disabled(selectedLocation == nil)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 120)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                // 顶部图片 + 文字
                ZStack(alignment: .bottomLeading) {
                    Image("HomePageImage")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 220)
                        .clipped()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Title(text: "Good Morning,", fontSize: 24, color: Color.white)
                        Title(text: "\(session.user?.name ?? "Veygo Renter")", fontSize: 24, color: Color.white)
                        Title(text: "Diamond Member", fontSize: 13, color: Color.white)
                    }
                    .padding(.leading, 24)
                    .padding(.bottom, 10)
                }
                .padding(.bottom, 16)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .ignoresSafeArea()
            .navigationDestination(for: HomeDestination.self) { dest in
                switch dest {
                case .apartment:
                    Text("Apartment")
                case .university:
                    if let id = selectedLocation {
                        FindCarView(path: $path, startDate: $startDate, endDate: $endDate, apartmentId: id)
                    } else {
                        Text("Select a location first")
                    }
                }
            }
            .onAppear {
                Task {
                    await ApiCallActor.shared.appendApi { token, userId in
                        await fetchUniversitiesAsync()
                    }
                }
            }
            .background(Color("MainBG"))
            .refreshable {
                Task {
                    await ApiCallActor.shared.appendApi { token, userId in
                        await fetchUniversitiesAsync()
                    }
                }
            }
        }
    }
    
    @ApiCallActor func fetchUniversitiesAsync() async -> ApiTaskResponse {
        let request = veygoCurlRequest(
            url: "/api/v1/apartment/get-universities",
            method: .get
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    alertTitle = "Server Error"
                    alertMessage = "Invalid protocol"
                    showAlert = true
                }
                return .doNothing
            }
            
            guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                await MainActor.run {
                    alertTitle = "Server Error"
                    alertMessage = "Invalid content"
                    showAlert = true
                }
                return .doNothing
            }
            
            switch httpResponse.statusCode {
            case 200:
                nonisolated struct RequestSuccessBody: Decodable {
                    let universities: [Apartment]
                }
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(RequestSuccessBody.self, from: data) else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                await MainActor.run {
                    self.universities = decodedBody.universities
                    if let rentersUniversity = self.universities.getItemBy(id: session.user?.apartmentId ?? 2),
                       rentersUniversity.uniId == 1 {
                        self.selectedLocation = rentersUniversity.id
                    } else {
                        self.selectedLocation = 2
                    }
                }
                return .doNothing
            case 405:
                await MainActor.run {
                    alertTitle = "Internal Error"
                    alertMessage = "Method not allowed, please contact the developer dev@veygo.rent"
                    showAlert = true
                }
                return .doNothing
            default:
                await MainActor.run {
                    alertTitle = "Application Error"
                    alertMessage = "Unrecognized response, make sure you are running the latest version"
                    showAlert = true
                }
                return .doNothing
            }
        } catch {
            await MainActor.run {
                alertTitle = "Internal Error"
                alertMessage = "\(error.localizedDescription)"
                showAlert = true
            }
            return .doNothing
        }
    }
}
