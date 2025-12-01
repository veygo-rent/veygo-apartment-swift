import SwiftUI
import UserNotifications
import Crisp

enum HomeDestination: Hashable {
    case university(apartment: Apartment)
    case apartment
    case vehicleDetails(vehicle: VehicleWithBlockedDurations, location: Location, apartment: Apartment, startDate: Date, endDate: Date)
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
    
    @FocusState private var couponIsFocused: Bool
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @EnvironmentObject var session: UserSession
    
    @AppStorage("apns_token") var apns_token: String = ""
    
    @State private var selectedToggle: RentalOption = .university
    @State private var selectedLocation: Apartment.ID? = nil
    
    @State private var showCurrentTrip: Bool = false
    
    @State private var startDate: Date = {
        let start = Date().addingTimeInterval(15 * 60)
        return roundUpToNextQuarter(from: start)
    }()
    @State private var endDate: Date = {
        let end = Date().addingTimeInterval(45 * 60)
        return roundUpToNextQuarter(from: end)
    }()
    
    @State private var promoCodeInput: String = ""
    @State private var promoCodeActual: String = ""
    @Binding var universities: [Apartment]
    
    @State private var path: [HomeDestination] = []
    
    @State private var appliedPromoCode: PublishPromo? = nil
    
    @State private var currentTrip: CurrentTrip? = nil
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                ScrollView {
                    GlassEffectContainer {
                        VStack(alignment: .leading, spacing: 16) {
                            // Make a Reservation & others
                            Title(text: "Make a Reservation", fontSize: 20, color: Color("TextBlackPrimary"))
                                .padding(.horizontal, 24)
                            /// Implementing Apartment UI later
                            SlidingToggleButton(selectedOption: $selectedToggle)
                                .padding(.horizontal, 24)
                                .sensoryFeedback(.selection, trigger: selectedToggle)
                            if selectedToggle == .university {
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
                                    InputWithInlinePrompt(promptText: "Promo code / coupon", userInput: $promoCodeInput)
                                        .focused($couponIsFocused)
                                        .onChange(of: promoCodeInput) { old, newValue in
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
                                            if promoCodeInput != finalResult {
                                                promoCodeInput = finalResult
                                            }
                                        }
                                    
                                    SecondaryButtonLg(text: "Apply") {
                                        couponIsFocused = false
                                        if !promoCodeInput.isEmpty {
                                            Task {
                                                await ApiCallActor.shared.appendApi { token, userId in
                                                    await checkPromoAsync(token, userId)
                                                }
                                            }
                                        } else {
                                            if !promoCodeActual.isEmpty {
                                                alertTitle = "Coupon Removed"
                                                alertMessage = "Code \(promoCodeActual) has been removed."
                                                promoCodeActual = ""
                                                showAlert = true
                                            }
                                        }
                                    }
                                    .frame(width: 92)
                                }
                                .padding(.horizontal, 24)
                                
                                PrimaryButtonLg(text: "Vehicle Look Up") {
                                    promoCodeInput = promoCodeActual
                                    if let selectedLocation, let university = universities.getItemBy(id: selectedLocation) {
                                        path.append(.university(apartment: university))
                                    }
                                }
                                .disabled(selectedLocation == nil || couponIsFocused)
                                .padding(.horizontal, 24)
                            } else {
                                Text("Coming soon...")
                                    .padding(.horizontal, 24)
                            }
                        }
                        .padding(.bottom, 120)
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .alert(alertTitle, isPresented: $showAlert) {
                    Button("OK") {
                        if clearUserTriggered {
                            session.user = nil
                        }
                    }
                } message: {
                    Text(alertMessage)
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
                    couponIsFocused = false
                }
                .onAppear{
                    if let renter = session.user {
                        CrispSDK.user.email = renter.studentEmail
                        CrispSDK.user.phone = renter.phone
                        CrispSDK.user.nickname = renter.name
                    }
                }
                .ignoresSafeArea()
                .navigationDestination(for: HomeDestination.self) { dest in
                    switch dest {
                    case .apartment:
                        ListCarView()
                    case let .university(apt):
                        FindCarView(path: $path, startDate: $startDate, endDate: $endDate, apartment: apt)
                    case let .vehicleDetails(vehicle, location, apartment, startDate, endDate):
                        VehicleDetailView(path: $path, startTime: startDate, endTime: endDate, apartment: apartment, vehicleWithBlocksAndLocationInfo: (vehicle, location))
                    }
                }
                .onAppear {
                    let center = UNUserNotificationCenter.current()
                    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        if granted {
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        }
                    }
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await fetchUniversitiesAsync()
                        }
                    }
                }
                .background(Color("MainBG").ignoresSafeArea(.all))
                .refreshable {
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await fetchUniversitiesAsync()
                        }
                    }
                }
                .onChange(of: apns_token) { oldValue, newValue in
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await updateApnsTokenAsync(token, userId)
                        }
                    }
                }
                
                if let currentTrip = currentTrip {
                    Button {
                        showCurrentTrip = true
                    } label: {
                        HStack {
                            Image(systemName: "key.2.on.ring")
                                .font(.headline)
                            Text("Current Trip")
                                .font(.headline)
                        }
                        .padding(4)
                        
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Color("TextLink").opacity(0.8))
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
            }
            .fullScreenCover(isPresented: $showCurrentTrip) {
                CurrentTripView()
            }
        }
    }
    
    @ApiCallActor func updateApnsTokenAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let apns_token = await apns_token
            let user = await MainActor.run { self.session.user }
            
            if !token.isEmpty && userId > 0, user != nil,
               !apns_token.isEmpty {
                let body: [String: String] = ["apns": apns_token]
                let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(body)
                let request = veygoCurlRequest(url: "/api/v1/user/update-apns", method: .post, headers: ["auth": "\(token)$\(userId)"], body: jsonData)
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertTitle = ErrorResponse.WRONG_PROTOCOL.title
                        alertMessage = ErrorResponse.WRONG_PROTOCOL.message
                        showAlert = true
                    }
                    return .doNothing
                }
                switch httpResponse.statusCode {
                case 200:
                    if let token = extractToken(from: response, for: "Updating APNs token") {
                        return .renewSuccessful(token: token)
                    } else {
                        return .doNothing
                    }
                case 401:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E401
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    }
                    return .clearUser
                case 405:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E405
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    }
                    return .doNothing
                default:
                    let body = ErrorResponse.E_DEFAULT
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                    return .doNothing
                }
            }
            return .doNothing
        } catch {
            await MainActor.run {
                alertTitle = "Internal Error"
                alertMessage = "\(error.localizedDescription)"
                showAlert = true
            }
            return .doNothing
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
                if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                } else {
                    let decodedBody = ErrorResponse.E405
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                }
                return .doNothing
            default:
                let body = ErrorResponse.E_DEFAULT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
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
    
    @ApiCallActor func checkPromoAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            
            if !token.isEmpty && userId > 0, user != nil {
                
                struct CheckPromoBody: Encodable {
                    let code: String
                    let dateOfRental: Int
                    let apartmentId: Int
                }
                
                let body = await CheckPromoBody(
                    code: await promoCodeInput,
                    dateOfRental: Int(await startDate.timeIntervalSince1970),
                    apartmentId: selectedLocation ?? 1
                )
                
                let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(body)
                
                let request = veygoCurlRequest(url: "/api/v1/user/verify-promo", method: .post, headers: ["auth": "\(token)$\(userId)"], body: jsonData)
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid protocol"
                        showAlert = true
                    }
                    return .doNothing
                }
                switch httpResponse.statusCode {
                case 200:
                    let promo: PublishPromo = try! VeygoJsonStandard.shared.decoder.decode(PublishPromo.self, from: data)
                    await MainActor.run {
                        appliedPromoCode = promo
                        alertTitle = "Coupon Applied"
                        alertMessage = "Enjoy your \(VeygoCurrencyStandard.shared.dollarFormatter.string(from: promo.amount as NSNumber)!) off!"
                        showAlert = true
                        promoCodeActual = promoCodeInput
                    }
                    let token = extractToken(from: response, for: "Validating promo code") ?? ""
                    return .renewSuccessful(token: token)
                case 401:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E401
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            clearUserTriggered = true
                        }
                    }
                    return .clearUser
                case 403:
                    guard let errorResponse: ErrorResponse = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Request Forbidden"
                            alertMessage = "Please check your permissions."
                            showAlert = true
                            promoCodeInput = promoCodeActual
                        }
                        let token = extractToken(from: response, for: "Validating promo code") ?? ""
                        return .renewSuccessful(token: token)
                    }
                    await MainActor.run {
                        alertTitle = errorResponse.title
                        alertMessage = errorResponse.message
                        showAlert = true
                        promoCodeInput = promoCodeActual
                    }
                    let token = extractToken(from: response, for: "Validating promo code") ?? ""
                    return .renewSuccessful(token: token)
                case 405:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E405
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    }
                    return .doNothing
                default:
                    let body = ErrorResponse.E_DEFAULT
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                    return .doNothing
                }
            }
            return .doNothing
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

struct CurrentTripView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            VStack {
                Text("Hello, World!")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("MainBG").ignoresSafeArea(.all))
            .toolbar {
                ToolbarItem {
                    Button("Dismiss", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }

        }
    }
}
