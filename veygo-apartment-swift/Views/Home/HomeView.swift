//
//  HomeView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/12/26.
//

import SwiftUI
import MapKit
import UserNotifications

enum RentalOption: String, CaseIterable, Identifiable {
    case university, apartment
    var id: Self { self }
}

struct HomeView: View {
    @Environment(Session.self) private var session
    @Environment(Router.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    @FocusState private var couponIsFocused: Bool

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    @AppStorage("apns_token") private var apnsToken: String = ""

    @State private var selectedToggle: RentalOption = .university
    @State private var selectedLocation: Apartment.ID? = nil
    @State private var universities: [Apartment] = []

    @State private var showCurrentTrip: Bool = false
    @State private var currentTrip: TripDetailedInfo? = nil

    @State private var startDate: Date = Date().nextQuarterHour().addingTimeInterval(15 * 60)
    @State private var endDate: Date = Date().nextQuarterHour().addingTimeInterval(45 * 60)

    @State private var promoCodeInput: String = ""
    @State private var promoCodeActual: String = ""
    @State private var appliedPromoCode: PublishPromo? = nil

    private var selectedUniversity: Apartment? {
        guard let selectedLocation else { return nil }
        return universities.getItemBy(id: selectedLocation)
    }

    var body: some View {
        // Tab root — no NavigationStack; AppView owns the outer stack and
        // registers HomeDestination destinations.
        Group {
            if let user = session.renter {
                content(user: user)
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func content(user: PublishRenter) -> some View {
        ZStack {
            ScrollView {
                GlassEffectContainer {
                    VStack(alignment: .leading, spacing: 16) {
                        Title(text: "Make a Reservation", fontSize: 20, color: Color("TextBlackPrimary"))
                            .padding(.horizontal, 24)

                        if selectedToggle == .university {
                            Dropdown(
                                selectedOption: $selectedLocation,
                                labelText: .constant("Rental location"),
                                universityOptions: $universities
                            )
                            .padding(.horizontal, 24)

                            DatePanel(
                                startDate: $startDate,
                                endDate: $endDate,
                                isEditMode: true,
                                schoolTimezoneIdentifier: selectedUniversity?.timezone
                            )
                            .padding(.horizontal, 24)

                            HStack(spacing: 16) {
                                InputWithInlinePrompt(userInput: $promoCodeInput, promptText: "Promo code / coupon")
                                    .focused($couponIsFocused)
                                    .onChange(of: promoCodeInput) { _, newValue in
                                        let cleaned = sanitizePromo(newValue)
                                        if promoCodeInput != cleaned { promoCodeInput = cleaned }
                                    }

                                SecondaryButtonLg(text: "Apply") {
                                    couponIsFocused = false
                                    if !promoCodeInput.isEmpty {
                                        Task { await applyPromo() }
                                    } else if !promoCodeActual.isEmpty {
                                        present(title: "Coupon Removed", message: "Code \(promoCodeActual) has been removed.")
                                        promoCodeActual = ""
                                        appliedPromoCode = nil
                                    }
                                }
                                .frame(width: 128)
                            }
                            .padding(.horizontal, 24)

                            PrimaryButtonLg(text: "Vehicle Look Up") {
                                promoCodeInput = promoCodeActual
                                if let university = selectedUniversity {
                                    router.push(HomeDestination.university(
                                        apartment: university,
                                        startDate: startDate,
                                        endDate: endDate,
                                        promo: appliedPromoCode
                                    ))
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
            .safeAreaInset(edge: .top, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    Image("HomePageImage")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 220)
                        .clipped()

                    VStack(alignment: .leading, spacing: 4) {
                        Title(text: "Good Morning,", fontSize: 24, color: .white)
                        Title(text: user.name, fontSize: 24, color: .white)
                        Title(text: "\(user.planTier.rawValue) Member", fontSize: 13, color: .white)
                    }
                    .padding(.leading, 24)
                    .padding(.bottom, 10)
                }
                .padding(.bottom, 16)
            }
            .onTapGesture { couponIsFocused = false }
            .ignoresSafeArea(.container)
            .background(Color("MainBG").ignoresSafeArea(.all))
            .refreshable { await loadAll() }

            if currentTrip != nil {
                Button {
                    showCurrentTrip = true
                } label: {
                    HStack {
                        Image(systemName: "key.2.on.ring").font(.headline)
                        Text("Current Trip").font(.headline)
                    }
                    .padding(4)
                }
                .buttonStyle(.glassProminent)
                .tint(Color("TextLink").opacity(0.8))
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .task {
            requestPushAuthorization()
            await loadAll()
        }
        .onChange(of: apnsToken) { _, _ in
            Task { await updateApnsToken() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await loadCurrentAgreement() }
            }
        }
        .fullScreenCover(isPresented: $showCurrentTrip, onDismiss: {
            Task { await loadCurrentAgreement() }
        }) {
            CurrentTripView(currentTrip: $currentTrip)
        }
    }

    // MARK: - Helpers

    /// Keep letters/numbers, allow single dashes (not leading), uppercase.
    private func sanitizePromo(_ input: String) -> String {
        var result = ""
        var previousWasDash = false
        for char in input {
            if char.isLetter || char.isNumber {
                result.append(char)
                previousWasDash = false
            } else if char == "-" && !previousWasDash && !result.isEmpty {
                result.append(char)
                previousWasDash = true
            }
        }
        return result.uppercased()
    }

    private func requestPushAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    private func loadAll() async {
        await loadUniversities()
        await loadCurrentAgreement()
    }

    // MARK: - Universities

    private func loadUniversities() async {
        do {
            let list = try await fetchUniversities()
            universities = list
            if let mine = list.getItemBy(id: session.renter?.apartmentId ?? 2), mine.uniId == 1 {
                selectedLocation = mine.id
            } else {
                selectedLocation = 2
            }
        } catch let error as VeygoError {
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func fetchUniversities() async throws -> [Apartment] {
        let request = veygoCurlRequest(url: "/api/v1/apartment/get-universities", method: .get)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw VeygoError.unknown }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return try VeygoJsonStandard.shared.decoder.decode([Apartment].self, from: data)
            } else {
                let decodedError = (try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)) ?? .E_DEFAULT
                throw VeygoError.server(status: httpCode, error: decodedError)
            }
        } catch let error as URLError {
            throw VeygoError.network(error)
        } catch _ as DecodingError {
            throw VeygoError.decoding
        } catch let error as VeygoError {
            throw error
        } catch {
            throw VeygoError.unknown
        }
    }

    // MARK: - Current agreement

    private func loadCurrentAgreement() async {
        do {
            let trip = try await fetchCurrentAgreement(session: session)
            currentTrip = trip
            if trip == nil { showCurrentTrip = false }
        } catch let error as VeygoError {
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    // MARK: - Promo

    private func applyPromo() async {
        do {
            let promo = try await verifyPromo(code: promoCodeInput)
            appliedPromoCode = promo
            promoCodeActual = promoCodeInput
            let amount = VeygoCurrencyStandard.shared.dollarFormatter.string(from: promo.amount.value as NSDecimalNumber) ?? "$0.00"
            present(title: "Coupon Applied", message: "Enjoy your \(amount) off!")
        } catch let error as VeygoError {
            switch error {
            case .unauthorized:
                session.clear()
                present(error.display)
            case .server(let status, _) where status == 403:
                promoCodeInput = promoCodeActual   // revert to last valid code
                present(error.display)
            default:
                present(error.display)
            }
        } catch {
            present(.E_DEFAULT)
        }
    }

    private struct CheckPromoBody: Encodable {
        let code: String
        let dateOfRental: Int
        let apartmentId: Int
    }

    private func verifyPromo(code: String) async throws -> PublishPromo {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else { throw VeygoError.unknown }

        let body = CheckPromoBody(
            code: code,
            dateOfRental: Int(startDate.timeIntervalSince1970),
            apartmentId: selectedLocation ?? 1
        )
        let jsonData = try VeygoJsonStandard.shared.encoder.encode(body)
        let request = veygoCurlRequest(
            url: "/api/v1/user/verify-promo",
            method: .post,
            headers: ["auth": "\(token)$\(userId)"],
            body: jsonData
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw VeygoError.unknown }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return try VeygoJsonStandard.shared.decoder.decode(PublishPromo.self, from: data)
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.unauthorized(decodedError)
            } else {
                let decodedError = (try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)) ?? .E_DEFAULT
                throw VeygoError.server(status: httpCode, error: decodedError)
            }
        } catch let error as URLError {
            throw VeygoError.network(error)
        } catch _ as DecodingError {
            throw VeygoError.decoding
        } catch let error as VeygoError {
            throw error
        } catch {
            throw VeygoError.unknown
        }
    }

    // MARK: - APNs

    private func updateApnsToken() async {
        guard !apnsToken.isEmpty else { return }
        do {
            try await updateApnsTokenRequest(apnsToken)
        } catch let error as VeygoError {
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func updateApnsTokenRequest(_ apns: String) async throws {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else { throw VeygoError.unknown }

        let jsonData = try VeygoJsonStandard.shared.encoder.encode(["apns": apns])
        let request = veygoCurlRequest(
            url: "/api/v1/user/update-apns",
            method: .post,
            headers: ["auth": "\(token)$\(userId)"],
            body: jsonData
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw VeygoError.unknown }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.unauthorized(decodedError)
            } else {
                let decodedError = (try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)) ?? .E_DEFAULT
                throw VeygoError.server(status: httpCode, error: decodedError)
            }
        } catch let error as URLError {
            throw VeygoError.network(error)
        } catch _ as DecodingError {
            throw VeygoError.decoding
        } catch let error as VeygoError {
            throw error
        } catch {
            throw VeygoError.unknown
        }
    }

    // MARK: - Alert

    private func present(_ error: ErrorResponse) {
        present(title: error.title, message: error.message)
    }

    private func present(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Shared: current agreement fetch (used by HomeView + CurrentTripView)

/// GET /agreement/current. Returns nil on 404 (no active trip).
@MainActor
private func fetchCurrentAgreement(session: Session) async throws -> TripDetailedInfo? {
    let token = session.token
    let userId = session.userId
    guard !token.isEmpty, userId > 0 else { throw VeygoError.unknown }

    let request = veygoCurlRequest(
        url: "/api/v1/agreement/current",
        method: .get,
        headers: ["auth": "\(token)$\(userId)"]
    )
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw VeygoError.unknown }
        let httpCode = httpResponse.statusCode

        if httpCode == 200 {
            return try VeygoJsonStandard.shared.decoder.decode(TripDetailedInfo.self, from: data)
        } else if httpCode == 404 {
            return nil
        } else if httpCode == 401 {
            let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
            throw VeygoError.unauthorized(decodedError)
        } else {
            let decodedError = (try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)) ?? .E_DEFAULT
            throw VeygoError.server(status: httpCode, error: decodedError)
        }
    } catch let error as URLError {
        throw VeygoError.network(error)
    } catch _ as DecodingError {
        throw VeygoError.decoding
    } catch let error as VeygoError {
        throw error
    } catch {
        throw VeygoError.unknown
    }
}

// MARK: - Current trip (modal)

struct CurrentTripView: View {
    @Environment(Session.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    @Binding var currentTrip: TripDetailedInfo?

    @State private var checkOut: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    @State private var locationManager = CLLocationManager()
    @State private var route: MKPolyline? = nil

    var body: some View {
        // Modal — owns its own NavigationStack.
        NavigationStack {
            if let currentTrip {
                tripContent(currentTrip)
            } else {
                Text("Hello World")
                    .toolbar {
                        ToolbarItem {
                            Button("Dismiss", systemImage: "xmark") { dismiss() }
                        }
                    }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { loadRoute() }
        }
    }

    @ViewBuilder
    private func tripContent(_ currentTrip: TripDetailedInfo) -> some View {
        let isPickedUp = currentTrip.agreement.actualPickupTime != nil
        let carCoordinate = CLLocationCoordinate2D(
            latitude: currentTrip.location.latitude,
            longitude: currentTrip.location.longitude
        )

        Map {
            UserAnnotation()
            if let route {
                MapPolyline(route)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round, dash: [4, 3]))
            }
            Marker(currentTrip.vehicle.name, systemImage: "car", coordinate: carCoordinate)
                .tint(.purple)
        }
        .mapControls {
            MapCompass()
            if locationManager.authorizationStatus == .authorizedWhenInUse {
                MapUserLocationButton()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("From: \(VeygoDatetimeStandard.shared.formattedDateTime(currentTrip.agreement.rsvpPickupTime))")
                            .font(.footnote)
                            .foregroundStyle(.textBlackPrimary)
                        Text("To: \(VeygoDatetimeStandard.shared.formattedDateTime(currentTrip.agreement.rsvpDropOffTime))")
                            .font(.footnote)
                            .foregroundStyle(.textBlackPrimary)
                    }
                    Spacer()
                    SecondaryButton(text: "Extend") {
                        print("Extend Button Pressed")
                    }
                    .frame(width: 100)
                    .disabled(Date() > currentTrip.agreement.rsvpDropOffTime)
                }
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("\(currentTrip.vehicle.make) \(currentTrip.vehicle.model)")
                                .foregroundStyle(.textBlackSecondary)
                            Text(currentTrip.vehicle.name)
                                .foregroundStyle(.textBlackPrimary)
                                .fontWeight(.light)
                        }
                        Text("License Plate: \(currentTrip.vehicle.licenseState) \(currentTrip.vehicle.licenseNumber)")
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
                        let item = MKMapItem(location: CLLocation(latitude: carCoordinate.latitude, longitude: carCoordinate.longitude), address: nil)
                        item.name = currentTrip.vehicle.name
                        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeTransit])
                    }
                    .buttonStyle(.glass)
                    .tint(.accent)

                    Button(isPickedUp ? "Unlock" : "Honk", systemImage: isPickedUp ? "lock.open.fill" : "speaker.wave.3.fill") {
                        Task {
                            if isPickedUp {
                                await unlock(confirmation: currentTrip.agreement.confirmation)
                            } else {
                                await honk()
                            }
                        }
                    }
                    .buttonStyle(.glass)
                    .tint(.accent)
                    .disabled(Date() < currentTrip.agreement.rsvpPickupTime.addingTimeInterval(-15 * 60))
                }
                PrimaryButton(text: isPickedUp ? "Return" : "Pick Up") {
                    checkOut = true
                }
                .padding(.top, 24)
                .disabled(currentTrip.agreement.rsvpPickupTime > Date())
            }
            .frame(maxWidth: .infinity)
            .padding(28)
            .background(.ultraThinMaterial)
            .cornerRadius(28)
            .padding(.horizontal)
        }
        .toolbar {
            ToolbarItem {
                Button("Dismiss", systemImage: "xmark") { dismiss() }
            }
        }
        .onAppear { loadRoute() }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $checkOut) {
            InspectionSheet(
                currentTrip: $currentTrip,
                mode: isPickedUp ? .dropOff : .pickUp,
                onActionSuccess: {
                    if isPickedUp {
                        checkOut = false
                        dismiss()
                    } else {
                        Task { await reloadCurrentTrip() }
                    }
                }
            )
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Route

    private func loadRoute() {
        guard let userLocation = locationManager.location,
              let carLocation = currentTrip?.location else { return }
        let request = MKDirections.Request()
        request.source = MKMapItem(location: userLocation, address: nil)
        request.destination = MKMapItem(location: CLLocation(latitude: carLocation.latitude, longitude: carLocation.longitude), address: nil)
        request.transportType = .walking
        let directions = MKDirections(request: request)
        Task {
            let response = try? await directions.calculate()
            if let first = response?.routes.first {
                route = first.polyline
            }
        }
    }

    // MARK: - Reload

    private func reloadCurrentTrip() async {
        do {
            currentTrip = try await fetchCurrentAgreement(session: session)
            loadRoute()
        } catch let error as VeygoError {
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    // MARK: - Honk / Unlock

    private func honk() async {
        do {
            try await simpleGet("/api/v1/vehicle/user-identify")
            present(title: "Honk Requested", message: "Honk request sent successfully.")
        } catch let error as VeygoError {
            switch error {
            case .unauthorized:
                session.clear()
                present(error.display)
            case .server(let status, _) where status == 404:
                break   // original: silently ignore
            default:
                present(error.display)
            }
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func unlock(confirmation: String) async {
        do {
            try await simpleGet("/api/v1/agreement/unlock/\(confirmation)")
            present(title: "Unlock Requested", message: "Unlock request sent successfully.")
        } catch let error as VeygoError {
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    /// Authenticated GET where 200 = success and everything else is an error.
    private func simpleGet(_ path: String) async throws {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else { throw VeygoError.unknown }

        let request = veygoCurlRequest(url: path, method: .get, headers: ["auth": "\(token)$\(userId)"])
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw VeygoError.unknown }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.unauthorized(decodedError)
            } else {
                let decodedError = (try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)) ?? .E_DEFAULT
                throw VeygoError.server(status: httpCode, error: decodedError)
            }
        } catch let error as URLError {
            throw VeygoError.network(error)
        } catch _ as DecodingError {
            throw VeygoError.decoding
        } catch let error as VeygoError {
            throw error
        } catch {
            throw VeygoError.unknown
        }
    }

    // MARK: - Alert

    private func present(_ error: ErrorResponse) {
        present(title: error.title, message: error.message)
    }

    private func present(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Pick-up / drop-off inspection sheet

private struct InspectionSheet: View {
    enum Mode {
        case pickUp, dropOff

        var submitButtonText: String {
            switch self {
            case .pickUp:  return "Submit Pick Up Images"
            case .dropOff: return "Submit Return Images"
            }
        }
        var endpointPath: String {
            switch self {
            case .pickUp:  return "/api/v1/agreement/check-out"
            case .dropOff: return "/api/v1/agreement/check-in"
            }
        }
    }

    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss

    @Binding var currentTrip: TripDetailedInfo?
    let mode: Mode
    let onActionSuccess: () -> Void

    @State private var images = InspectionImages()
    @State private var isSubmitting: Bool = false
    @State private var isShowingCamera = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        // Sheet — owns its own NavigationStack.
        NavigationStack {
            ScrollView {
                SecondaryButton(text: images.nextCaptureTitle) {
                    isShowingCamera = true
                }
                .padding()
                .disabled(images.allCaptured)

                PrimaryButton(text: mode.submitButtonText) {
                    Task { await submitInspection() }
                }
                .padding()
                .disabled(isSubmitting || !images.allUploaded)

                LazyVGrid(columns: gridColumns, spacing: 36) {
                    ForEach(InspectionImageSlot.allCases, id: \.self) { slot in
                        InspectionImageTile(slot: slot, upload: images[slot]) {
                            images[slot] = nil
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color("MainBG").ignoresSafeArea())
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraImagePicker { image in
                    handleCapture(image)
                }
                .ignoresSafeArea(edges: .all)
            }
            .toolbar {
                ToolbarItem {
                    Button("Dismiss", systemImage: "xmark") { dismiss() }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Capture → upload (signed-URL flow)

    private func handleCapture(_ image: UIImage) {
        guard let data = image.heicData() else {
            present(title: "Camera Error", message: "Failed to read captured image.")
            return
        }
        guard let reservation = images.reserve(image) else { return }
        Task {
            await uploadImage(
                data: data,
                fileName: "vehicle_inspection_camera_\(reservation.id.uuidString).heic",
                slot: reservation.slot,
                uploadId: reservation.id
            )
        }
    }

    private func uploadImage(data: Data, fileName: String, slot: InspectionImageSlot, uploadId: UUID) async {
        do {
            let link = try await requestUploadLink(fileName: fileName)
            try await putToSignedURL(link.fileLink, data: data, contentType: "image/heic")
            let storedName = link.fileName
            images.complete(slot: slot, id: uploadId, filePath: storedName)
        } catch let error as VeygoError {
            images.fail(slot: slot, id: uploadId)
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            images.fail(slot: slot, id: uploadId)
            present(.E_DEFAULT)
        }
    }

    private func requestUploadLink(fileName: String) async throws -> FileLink {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else { throw VeygoError.unknown }
        guard let vin = currentTrip?.vehicle.vin else { throw VeygoError.unknown }

        let jsonData = try VeygoJsonStandard.shared.encoder.encode(["vehicle_vin": vin, "file_name": fileName])
        let request = veygoCurlRequest(
            url: "/api/v1/vehicle/request-upload-link",
            method: .post,
            headers: ["auth": "\(token)$\(userId)"],
            body: jsonData
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw VeygoError.unknown }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return try VeygoJsonStandard.shared.decoder.decode(FileLink.self, from: data)
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.unauthorized(decodedError)
            } else {
                let decodedError = (try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)) ?? .E_DEFAULT
                throw VeygoError.server(status: httpCode, error: decodedError)
            }
        } catch let error as URLError {
            throw VeygoError.network(error)
        } catch _ as DecodingError {
            throw VeygoError.decoding
        } catch let error as VeygoError {
            throw error
        } catch {
            throw VeygoError.unknown
        }
    }

    /// Plain PUT to the absolute Google signed URL — NOT veygoCurlRequest.
    private func putToSignedURL(_ urlString: String, data: Data, contentType: String) async throws {
        guard let url = URL(string: urlString) else { throw VeygoError.unknown }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300
        do {
            let (_, response) = try await URLSession.shared.upload(for: request, from: data)
            guard let httpResponse = response as? HTTPURLResponse else { throw VeygoError.unknown }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw VeygoError.server(status: httpResponse.statusCode, error: .E_DEFAULT)
            }
        } catch let error as URLError {
            throw VeygoError.network(error)
        } catch let error as VeygoError {
            throw error
        } catch {
            throw VeygoError.unknown
        }
    }

    // MARK: - Submit inspection

    private func submitInspection() async {
        isSubmitting = true
        defer { isSubmitting = false }

        guard
            let agreementId = currentTrip?.agreement.id,
            let left = images.path(for: .left),
            let right = images.path(for: .right),
            let front = images.path(for: .front),
            let back = images.path(for: .back),
            let frontRight = images.path(for: .frontRight),
            let frontLeft = images.path(for: .frontLeft),
            let backLeft = images.path(for: .rearLeft),
            let backRight = images.path(for: .rearRight)
        else {
            present(title: "Missing Photos", message: "Please capture and upload all required images before submitting.")
            return
        }

        let body: CheckInOutRequest = .withImagePath(
            agreementId: agreementId,
            leftImagePath: left,
            rightImagePath: right,
            frontImagePath: front,
            backImagePath: back,
            frontRightImagePath: frontRight,
            frontLeftImagePath: frontLeft,
            backLeftImagePath: backLeft,
            backRightImagePath: backRight
        )

        do {
            try await submitInspectionRequest(body)
            onActionSuccess()
            dismiss()
        } catch let error as VeygoError {
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func submitInspectionRequest(_ body: CheckInOutRequest) async throws {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else { throw VeygoError.unknown }

        let jsonData = try VeygoJsonStandard.shared.encoder.encode(body)
        let request = veygoCurlRequest(
            url: mode.endpointPath,
            method: .post,
            headers: ["auth": "\(token)$\(userId)", "Content-Type": "application/json"],
            body: jsonData,
            timeout: 20
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw VeygoError.unknown }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.unauthorized(decodedError)
            } else {
                let decodedError = (try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)) ?? .E_DEFAULT
                throw VeygoError.server(status: httpCode, error: decodedError)
            }
        } catch let error as URLError {
            throw VeygoError.network(error)
        } catch _ as DecodingError {
            throw VeygoError.decoding
        } catch let error as VeygoError {
            throw error
        } catch {
            throw VeygoError.unknown
        }
    }

    // MARK: - Alert

    private func present(_ error: ErrorResponse) {
        present(title: error.title, message: error.message)
    }

    private func present(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Title

private struct Title: View {
    var text: String
    var fontSize: CGFloat
    var color: Color

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundColor(color)
    }
}

private struct SlidingToggleButton: View {
    @Binding var selectedOption: RentalOption
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.textFieldBg)
                    .stroke(Color.textFieldFrame, lineWidth: 1)
                    .frame(maxWidth: .infinity, maxHeight: 42)
                
                // 蓝色滑块
                HStack {
                    if selectedOption == .apartment {
                        Spacer()
                    }
                    
                    RoundedRectangle(cornerRadius: 19)
                        .fill(Color.primaryButtonBg)
                        .frame(width: geometry.size.width / 2, height: 38).padding(.horizontal, 2)
                    
                    if selectedOption == .university {
                        Spacer()
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: selectedOption)
                
                // 文本按钮
                HStack(spacing: 0) {
                    Button("University") {
                        selectedOption = .university
                    }
                    .foregroundColor(selectedOption == .university ? Color.primaryButtonText : Color.secondaryButtonText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Button("Apartment") {
                        selectedOption = .apartment
                    }
                    .foregroundColor(selectedOption == .apartment ? Color.primaryButtonText : Color.secondaryButtonText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 42)
        }
        .frame(height: 42)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 19))
    }
}

