import SwiftUI
import _MapKit_SwiftUI
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
    @Environment(\.scenePhase) private var scenePhase
    
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
                        .padding(.bottom, 36)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
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
                .ignoresSafeArea(.container)
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
                        await ApiCallActor.shared.appendApi { token, userId in
                            await getCurrentAgreement(token, userId)
                        }
                    }
                }
                .background(Color("MainBG").ignoresSafeArea(.all))
                .refreshable {
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await fetchUniversitiesAsync()
                        }
                        await ApiCallActor.shared.appendApi { token, userId in
                            await getCurrentAgreement(token, userId)
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
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        Task {
                            await ApiCallActor.shared.appendApi { token, userId in
                                await getCurrentAgreement(token, userId)
                            }
                        }
                    }
                }
                
                if currentTrip != nil {
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
                CurrentTripView(currentTrip: $currentTrip)
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
    
    @ApiCallActor func getCurrentAgreement (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                let request = veygoCurlRequest(
                    url: "/api/v1/agreement/current",
                    method: .get,
                    headers: [
                        "auth": "\(token)$\(userId)"
                    ]
                )
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
                    let token = extractToken(from: response, for: "Loading current trip") ?? ""
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(CurrentTrip.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .renewSuccessful(token: token)
                    }
                    await MainActor.run {
                        self.currentTrip = decodedBody
                    }
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
                case 404:
                    await MainActor.run {
                        self.currentTrip = nil
                        self.showCurrentTrip = false
                    }
                    let token = extractToken(from: response, for: "Loading current trip") ?? ""
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
    @State private var checkIn: Bool = false
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) var dismiss
    @Binding var currentTrip: CurrentTrip?
    @EnvironmentObject var session: UserSession
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @State private var locationManager = CLLocationManager()
    @State private var route: MKPolyline? = nil
    var body: some View {
        NavigationStack {
            if currentTrip!.agreement.actualPickupTime == nil {
                Map {
                    UserAnnotation()
                    if let route = route {
                        MapPolyline(route)
                            .stroke(
                                Color.blue,
                                style: StrokeStyle(
                                    lineWidth: 1.5,
                                    lineCap: .round,
                                    lineJoin: .round,
                                    dash: [4, 3]
                                )
                            )
                    }
                    Marker(currentTrip!.vehicle.name, systemImage: "car", coordinate: CLLocationCoordinate2D(latitude: currentTrip!.location.latitude, longitude: currentTrip!.location.longitude))
                        .tint(.purple)
                }
                .mapControls {
                    MapCompass()
                    if locationManager.authorizationStatus == .authorizedWhenInUse {
                        MapUserLocationButton()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom, content: {
                    VStack {
                        HStack {
                            VStack (alignment: .leading) {
                                Text("Pick up: \(VeygoDatetimeStandard.shared.formattedDateTime(currentTrip!.agreement.rsvpPickupTime))")
                                    .font(.footnote)
                                    .fontWeight(.regular)
                                    .foregroundStyle(.textBlackPrimary)
                                Text("Drop off: \(VeygoDatetimeStandard.shared.formattedDateTime(currentTrip!.agreement.rsvpDropOffTime))")
                                    .font(.footnote)
                                    .fontWeight(.regular)
                                    .foregroundStyle(.textBlackPrimary)
                            }
                            Spacer()
                            SecondaryButton(text: "Extend") {
                                print("Extend Button Pressed")
                            }
                            .frame(width: 100)
                        }
                        HStack {
                            VStack (alignment: .leading) {
                                HStack {
                                    Text("\(currentTrip!.vehicle.make) \(currentTrip!.vehicle.model)")
                                        .foregroundStyle(.textBlackSecondary)
                                    Text(currentTrip!.vehicle.name)
                                        .foregroundStyle(.textBlackPrimary)
                                        .fontWeight(.light)
                                }
                                Text("License Plate: \(currentTrip!.vehicle.licenseState) \(currentTrip!.vehicle.licenseNumber)")
                                    .foregroundStyle(.textBlackPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Image("TempVehicle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100)
                        }
                        HStack(alignment: .center, spacing: 16) {
                            Button("Direction", systemImage: "map.fill") {
                                guard let trip = currentTrip else { return }
                                let item = MKMapItem(location: CLLocation(latitude: trip.location.latitude, longitude: trip.location.longitude), address: nil)
                                item.name = "\(trip.vehicle.name)"
                                let options = [
                                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeTransit,
                                ]
                                item.openInMaps(launchOptions: options)
                            }
                            .buttonStyle(.glass)
                            .tint(.accent)
                            Button("Honk", systemImage: "speaker.wave.3.fill") {
                                Task {
                                    await ApiCallActor.shared.appendApi { token, userId in
                                        await honkCurrentVehicle(token, userId)
                                    }
                                }
                            }
                            .buttonStyle(.glass)
                            .tint(.accent)
                            .disabled(Date() < currentTrip!.agreement.rsvpPickupTime.addingTimeInterval(-15 * 60))
                        }
                        PrimaryButton(text: "Check In") {
                            checkIn = true
                        }
                        .padding(.top, 24)
                        .disabled(currentTrip!.agreement.rsvpPickupTime > Date())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(28)
                    .background(.ultraThinMaterial)
                    .cornerRadius(28)
                    .padding(.horizontal)
                })
                .toolbar {
                    ToolbarItem {
                        Button("Dismiss", systemImage: "xmark") {
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    loadRoute()
                }
                .alert(alertTitle, isPresented: $showAlert) {
                    Button("OK") {
                        if clearUserTriggered {
                            session.user = nil
                        }
                    }
                } message: {
                    Text(alertMessage)
                }
                .sheet(isPresented: $checkIn) {
                    CheckInView(currentTrip: $currentTrip)
                        .presentationDragIndicator(.visible)
                }
            } else {
                EmptyView()
                    .toolbar {
                        ToolbarItem {
                            Button("Dismiss", systemImage: "xmark") {
                                dismiss()
                            }
                        }
                    }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                loadRoute()
            }
        }
    }
    
    func loadRoute() {
        if let userLocation = locationManager.location,
           let carLocation = currentTrip?.location {
            let request = MKDirections.Request()
            request.source = MKMapItem(location: userLocation, address: nil)
            request.destination = MKMapItem(location: CLLocation(latitude: carLocation.latitude, longitude: carLocation.longitude), address: nil)
            let directions = MKDirections(request: request)
            Task {
                let response = try? await directions.calculate()
                if let route = response?.routes.first {
                    self.route = route.polyline
                }
            }
        }
    }
    
    @ApiCallActor func honkCurrentVehicle (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                let request = veygoCurlRequest(
                    url: "/api/v1/vehicle/user-identify",
                    method: .get,
                    headers: [
                        "auth": "\(token)$\(userId)"
                    ]
                )
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
                    let token = extractToken(from: response, for: "Honking current vehicle") ?? ""
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
                case 404:
                    let token = extractToken(from: response, for: "Loading current trip") ?? ""
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

struct CheckInView: View {
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @EnvironmentObject var session: UserSession
    
    @Environment(\.dismiss) var dismiss
    
    // Stage 1: Eight corner images
    @Binding var currentTrip: CurrentTrip?
    
    @State private var isSubmitting: Bool = false
    @State private var isShowingCamera = false
    
    @State private var leftImage: (String, UIImage)? = nil
    @State private var rightImage: (String, UIImage)? = nil
    @State private var frontImage: (String, UIImage)? = nil
    @State private var backImage: (String, UIImage)? = nil
    @State private var rearRight: (String, UIImage)? = nil
    @State private var rearLeft: (String, UIImage)? = nil
    @State private var frontRight: (String, UIImage)? = nil
    @State private var frontLeft: (String, UIImage)? = nil

    private var nextCaptureButtonTitle: String {
        if leftImage == nil {
            return "Capture left image"
        } else if rightImage == nil {
            return "Capture right image"
        } else if frontImage == nil {
            return "Capture front image"
        } else if backImage == nil {
            return "Capture back image"
        } else if rearRight == nil {
            return "Capture rear-right image"
        } else if rearLeft == nil {
            return "Capture rear-left image"
        } else if frontRight == nil {
            return "Capture front-right image"
        } else if frontLeft == nil {
            return "Capture front-left image"
        } else {
            return "All photos captured"
        }
    }
    
    private var allImagesCaptured: Bool {
        leftImage != nil &&
        rightImage != nil &&
        frontImage != nil &&
        backImage != nil &&
        rearRight != nil &&
        rearLeft != nil &&
        frontRight != nil &&
        frontLeft != nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                SecondaryButton(text: nextCaptureButtonTitle) {
                    isShowingCamera = true
                }
                .disabled(isSubmitting || allImagesCaptured)
                PrimaryButton(text: "Submit Check-in Images") {
                    
                }
                .disabled(isSubmitting || !allImagesCaptured)
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraImagePicker { image in
                    // Convert to Data and upload
                    if let data = image.jpegData(compressionQuality: 0.5) {
                        Task {
                            await ApiCallActor.shared.appendApi { token, userId in
                                await submitFileAsync(
                                    token,
                                    userId,
                                    data,
                                    "vehicle_inspection_camera.jpg",
                                    image
                                )
                            }
                        }
                    } else {
                        // optional: show an error alert here
                        alertMessage = "Failed to read captured image."
                        alertTitle = "Camera Error"
                        showAlert = true
                    }
                }
                .ignoresSafeArea(edges: .all)
            }
            .toolbar {
                ToolbarItem {
                    Button("Dismiss", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") {
                    if clearUserTriggered {
                        session.user = nil
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    @ApiCallActor func submitFileAsync (_ token: String, _ userId: Int, _ file: Data, _ fileName: String, _ image: UIImage) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                
                let request = veygoCurlRequest(
                    url: "/api/v1/vehicle/upload-image",
                    method: .post,
                    headers: [
                        "auth": "\(token)$\(userId)",
                        "Content-Type": "application/octet-stream",
                        "file-name": fileName,
                        "vehicle-vin": await currentTrip?.vehicle.vin ?? ""
                    ],
                    body: file
                )
                
                await MainActor.run {
                    isSubmitting = true
                }
                let (data, response) = try await URLSession.shared.data(for: request)
                await MainActor.run {
                    isSubmitting = false
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid protocol"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                    if let decodedString = String(data: data, encoding: .utf8) {
                            print("Decoded String: \(decodedString)")
                        } else {
                            print("Decoding failed.")
                        }
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                switch httpResponse.statusCode {
                case 200:
                    let token = extractToken(from: response, for: "Submitting driver's license") ?? ""
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(FilePath.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .renewSuccessful(token: token)
                    }
                    await MainActor.run {
                        if leftImage == nil {
                            leftImage = (decodedBody.filePath, image)
                        } else if rightImage == nil {
                            rightImage = (decodedBody.filePath, image)
                        } else if frontImage == nil {
                            frontImage = (decodedBody.filePath, image)
                        } else if backImage == nil {
                            backImage = (decodedBody.filePath, image)
                        } else if rearRight == nil {
                            rearRight = (decodedBody.filePath, image)
                        } else if rearLeft == nil {
                            rearLeft = (decodedBody.filePath, image)
                        } else if frontRight == nil {
                            frontRight = (decodedBody.filePath, image)
                        } else if frontLeft == nil {
                            frontLeft = (decodedBody.filePath, image)
                        }
                    }
                    await MainActor.run {
                        alertTitle = "Uploaded Successfully"
                        alertMessage = "Uploaded your document successfully."
                        showAlert = true
                    }
                    return .renewSuccessful(token: token)
                case 400:
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) else {
                        let msg = ErrorResponse.E400
                        await MainActor.run {
                            alertTitle = msg.title
                            alertMessage = msg.message
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        alertTitle = decodedBody.title
                        alertMessage = decodedBody.message
                        showAlert = true
                    }
                    return .doNothing
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
}
