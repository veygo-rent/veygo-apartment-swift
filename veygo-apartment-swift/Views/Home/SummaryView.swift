//
//  SummaryView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 3/9/26.
//

import SwiftUI
import MapKit

struct SummaryView: View {
    
    @EnvironmentObject var session: UserSession
    
    @State private var paymentMethods: [PublishPaymentMethod] = []
    @State private var selectedPaymentMethod: PublishPaymentMethod?
    
    @State private var isLoadingPM: Bool = false
    @State private var isCreatingAgreement: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    @State private var returnHomeTriggered: Bool = false
    
    @Binding var path: [HomeDestination]
    
    let startDate: Date
    let endDate: Date
    
    let vehicle: PublishRenterVehicle
    let apartment: Apartment
    let location: Location
    let promo: PublishPromo?
    let mileagePackage: MileagePackage?
    let taxes: [Tax]
    
    let rateOffer: RateOffer
    
    var pricingStandard: VeygoPricingStandard { VeygoPricingStandard(apartment: apartment, vehicle: vehicle) }
    
    private var rawDuration: TimeInterval {
        max(0, endDate.timeIntervalSince(startDate))
    }
    
    private var hourlyRate: Decimal {
        vehicle.msrpFactor.value * apartment.durationRate.value * rateOffer.multiplier.value
    }
    
    private var rawHours: Decimal {
        Decimal(rawDuration) / Decimal(3600)
    }
    
    private var tier1Hours: Decimal {
        max(Decimal.zero, min(rawHours, Decimal(8)))
    }
    
    private var tier2Hours: Decimal {
        max(Decimal.zero, min(rawHours - Decimal(8), Decimal(160)))
    }
    
    private var tier3Hours: Decimal {
        max(Decimal.zero, rawHours - Decimal(168))
    }
    
    private var tier1Charge: Decimal {
        tier1Hours * hourlyRate
    }
    
    private var tier2HourlyRate: Decimal {
        hourlyRate * Decimal(string: "0.25")!
    }
    
    private var tier2Charge: Decimal {
        tier2Hours * tier2HourlyRate
    }
    
    private var tier3HourlyRate: Decimal {
        hourlyRate * Decimal(string: "0.15")!
    }
    
    private var tier3Charge: Decimal {
        tier3Hours * tier3HourlyRate
    }
    
    private var tripSubtotal: Decimal {
        tier1Charge + tier2Charge + tier3Charge
    }
    
    private var tripTotalHours: Decimal {
        tier1Hours + tier2Hours + tier3Hours
    }
    
    private var averageHourlyRate: Decimal {
        guard tripTotalHours > 0 else { return Decimal.zero }
        return tripSubtotal / tripTotalHours
    }
    
    private var mileageSubtotal: Decimal {
        guard let mileagePackage else { return Decimal.zero }
        return pricingStandard.mileagePackagePrice(for: mileagePackage)
    }
    
    private var subtotalBeforeDiscount: Decimal {
        tripSubtotal + mileageSubtotal
    }
    
    private var promoDiscount: Decimal {
        min(promo?.amount.value ?? Decimal.zero, subtotalBeforeDiscount)
    }
    
    private var subtotalBeforeTax: Decimal {
        max(Decimal.zero, subtotalBeforeDiscount - promoDiscount)
    }
    
    private var rawRentalDays: Int {
        guard rawDuration > 0 else { return 0 }
        return Int(ceil(rawDuration / (24 * 3600)))
    }
    
    private var taxLines: [TaxLine] {
        taxes
            .map { tax in
                let amount: Decimal
                switch tax.taxType {
                case .percent:
                    amount = subtotalBeforeTax * normalizedPercentMultiplier(tax.multiplier.value)
                case .daily:
                    amount = Decimal(rawRentalDays) * tax.multiplier.value
                case .fixed:
                    amount = tax.multiplier.value
                }
                return TaxLine(id: tax.id, name: tax.name, amount: max(Decimal.zero, amount))
            }
    }
    
    private var totalTax: Decimal {
        taxLines.reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    private var finalEstimatedTotal: Decimal {
        subtotalBeforeTax + totalTax
    }
    
    private func normalizedPercentMultiplier(_ multiplier: Decimal) -> Decimal {
        let absolute = multiplier < 0 ? -multiplier : multiplier
        if absolute > Decimal(1) {
            return multiplier / Decimal(100)
        }
        return multiplier
    }
    
    var body: some View {
        VStack {
            if let _ = session.user {
                GlassEffectContainer {
                    ZStack (alignment: .bottom) {
                        List {
                            Image(.tempVehicle)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 300, height: 130)
                                .clipped()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.mainBG)
                            
                            /// Vehicle Detail Section
                            VStack (alignment: .leading, spacing: 16) {
                                Text("\(vehicle.make) \(vehicle.model)")
                                    .foregroundStyle(Color.textBlackSecondary)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("\(vehicle.licenseState) \(vehicle.licenseNumber) \(vehicle.name)")
                                    .foregroundStyle(Color.textBlackPrimary)
                                    .font(.subheadline)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.mainBG)
                            
                            /// Itinerary Section
                            VStack (alignment: .leading, spacing: 16) {
                                Text("Itinerary")
                                    .foregroundStyle(Color.textBlackSecondary)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundStyle(Color.accent)
                                    Text("\(apartment.name) - \(location.name)")
                                        .foregroundStyle(Color.textBlackPrimary)
                                }
                                .font(.subheadline)
                                HStack {
                                    Image(systemName: "clock.badge.fill")
                                        .foregroundStyle(Color.textLink)
                                    Text("\(apartment.localizedDate(for: startDate))")
                                        .foregroundStyle(Color.textBlackPrimary)
                                }
                                .font(.subheadline)
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundStyle(Color.textLink)
                                    Text("\(apartment.localizedDate(for: endDate))")
                                        .foregroundStyle(Color.textBlackPrimary)
                                }
                                .font(.subheadline)
                                Map(
                                    initialPosition: .region(
                                        MKCoordinateRegion(
                                            center: CLLocationCoordinate2D(
                                                latitude: location.latitude,
                                                longitude: location.longitude
                                            ),
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        )
                                    ),
                                    interactionModes: []
                                ) {
                                    Marker(
                                        "Pickup Location",
                                        coordinate: CLLocationCoordinate2D(
                                            latitude: location.latitude,
                                            longitude: location.longitude
                                        )
                                    ).tint(.purple)
                                }
                                .frame(height: 160)
                                .cornerRadius(16)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.mainBG)
                            
                            /// Mileage Option Section
                            VStack (alignment: .leading, spacing: 16) {
                                Text("Mileage Option")
                                    .foregroundStyle(Color.textBlackSecondary)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                HStack {
                                    Image(systemName: "map.fill")
                                        .foregroundStyle(Color.accent)
                                    Text("^[Included distance: \(10 + (mileagePackage?.miles ?? 0)) mile](inflect: true)")
                                        .foregroundStyle(Color.textBlackPrimary)
                                }
                                .font(.subheadline)
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundStyle(Color.textLink)
                                    Text("\(pricingStandard.perMileSubtitle())")
                                        .foregroundStyle(Color.textBlackPrimary)
                                }
                                .font(.subheadline)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.mainBG)
                            
                            /// Payment Info Section
                            VStack (alignment: .leading, spacing: 16) {
                                Text("Payment Info")
                                    .foregroundStyle(Color.textBlackSecondary)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                NavigationLink {
                                    SelectPaymentCardView(
                                        paymentMethods: $paymentMethods,
                                        selectedPaymentMethod: $selectedPaymentMethod
                                    )
                                } label: {
                                    HStack(spacing: 16) {
                                        cardBrandImage(for: selectedPaymentMethod?.network ?? "")
                                            .frame(width: 48, height: 48)
                                            .cornerRadius(4)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(selectedPaymentMethod?.nickname ?? selectedPaymentMethod?.maskedCardNumber ?? "Select payment card")
                                                .foregroundStyle(Color.textBlackPrimary)
                                                .font(.subheadline)
                                            
                                            if let selectedPaymentMethod {
                                                Text("Expires: \(selectedPaymentMethod.expiration)")
                                                    .foregroundStyle(Color.textBlackSecondary)
                                                    .font(.footnote)
                                            } else {
                                                Text(isLoadingPM ? "Loading cards..." : "Tap to choose a card")
                                                    .foregroundStyle(Color.footNote)
                                                    .font(.footnote)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(Color.footNote)
                                    }
                                    .padding()
                                    .background(Color.cardBG)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                                .navigationLinkIndicatorVisibility(.hidden)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.mainBG)
                            
                            /// Price Details
                            VStack (alignment: .leading, spacing: 16) {
                                Text("Price Details")
                                    .foregroundStyle(Color.textBlackSecondary)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                VStack (spacing: 10) {
                                    priceLine(
                                        title: "\(formatHours(tripTotalHours)) @ \(formatRate(averageHourlyRate))/hr",
                                        value: formatRate(tripSubtotal)
                                    )
                                    
                                    Divider()
                                    
                                    if promoDiscount > 0 {
                                        priceLine(
                                            title: "Promo (\(promo?.code ?? ""))",
                                            value: "-\(formatRate(promoDiscount))"
                                        )
                                        
                                        Divider()
                                    }
                                    
                                    if mileageSubtotal > 0 {
                                        priceLine(
                                            title: "Mileage package (\(10 + (mileagePackage?.miles ?? 0)) miles)",
                                            value: formatRate(mileageSubtotal)
                                        )
                                        Divider()
                                    }
                                    
                                    priceLine(title: "Subtotal before tax", value: formatRate(subtotalBeforeTax), weight: .semibold)
                                    
                                    if !taxLines.isEmpty {
                                        Divider()
                                        ForEach(taxLines) { taxLine in
                                            priceLine(
                                                title: "\(taxLine.name)",
                                                value: formatRate(taxLine.amount)
                                            )
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    priceLine(
                                        title: "Final total est.",
                                        value: formatRate(finalEstimatedTotal),
                                        weight: .bold
                                    )
                                }
                                .padding()
                                .background(Color.cardBG)
                                .cornerRadius(12)
                                
                                Text("Estimated total does not include fuel charges, tolls, or other fees that may occur during your trip.")
                                    .foregroundStyle(Color.footNote)
                                    .font(.footnote)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("A $200 deposit is required at the time of pick-up.")
                                    .foregroundStyle(Color.footNote)
                                    .font(.footnote)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                TextWithLink(fullText: "By proceeding with this booking, you agree to the Rental Terms.", highlightedTexts: [
                                    ("Rental Terms", { path.append(.rentalTerms) })
                                ])
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.mainBG)
                            .padding(.bottom, 80)
                        }
                        .scrollIndicators(.hidden)
                        .listStyle(.plain)
                        PrimaryButton(text: "Book Trip") {
                            if let paymentMethodId = selectedPaymentMethod?.id {
                                Task {
                                    await ApiCallActor.shared.appendApi { token, userId in
                                        await makeReservationAsync(token, userId, pmtId: paymentMethodId)
                                    }
                                }
                            }
                        }
                        .disabled(selectedPaymentMethod == nil || isCreatingAgreement)
                        .padding()
                        .alert(alertTitle, isPresented: $showAlert) {
                            Button("OK") {
                                if clearUserTriggered {
                                    session.user = nil
                                }
                                if returnHomeTriggered {
                                    path = []
                                }
                            }
                        } message: {
                            Text(alertMessage)
                        }
                        .onAppear {
                            Task {
                                await ApiCallActor.shared.appendApi { token, userId in
                                    await loadCardsAsync(token, userId)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .frame(maxWidth: .infinity)
        .navigationTitle(Text("Trip Summary"))
        .background(Color.mainBG, ignoresSafeAreaEdges: .all)
    }
    
    @ViewBuilder
    private func priceLine(title: String, value: String, weight: Font.Weight = .regular) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.textBlackPrimary)
                .fontWeight(weight)
            Spacer()
            Text(value)
                .foregroundStyle(Color.textBlackPrimary)
                .fontWeight(weight)
        }
        .font(.subheadline)
    }
    
    private func formatRate(_ amount: Decimal) -> String {
        VeygoCurrencyStandard.shared.dollarFormatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
    
    private func formatHours(_ hours: Decimal) -> String {
        if hours >= Decimal(24) {
            let days = NSDecimalNumber(decimal: hours / Decimal(24))
                .rounding(accordingToBehavior: NSDecimalNumberHandler(
                    roundingMode: .down,
                    scale: 0,
                    raiseOnExactness: false,
                    raiseOnOverflow: false,
                    raiseOnUnderflow: false,
                    raiseOnDivideByZero: false
                )).intValue
            let remainingHours = max(Decimal.zero, hours - Decimal(days * 24))
            let dayUnit = days == 1 ? "day" : "days"
            return "\(days) \(dayUnit) and \(formatHourNumber(remainingHours)) hr"
        }
        
        return "\(formatHourNumber(hours)) hr"
    }
    
    private func formatHourNumber(_ hours: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: hours as NSDecimalNumber) ?? "0"
    }
    
    private struct TaxLine: Identifiable {
        let id: Int
        let name: String
        let amount: Decimal
    }
    
    @ApiCallActor func loadCardsAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                let request = veygoCurlRequest(
                    url: "/api/v1/payment-method/get",
                    method: .get,
                    headers: [
                        "auth": "\(token)$\(userId)"
                    ]
                )
                await MainActor.run {
                    isLoadingPM = true
                }
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
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode([PublishPaymentMethod].self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        self.paymentMethods = decodedBody
                        if let selectedPaymentMethod,
                           !decodedBody.contains(where: { $0.id == selectedPaymentMethod.id }) {
                            self.selectedPaymentMethod = decodedBody.first
                        } else if self.selectedPaymentMethod == nil {
                            self.selectedPaymentMethod = decodedBody.first
                        }
                        isLoadingPM = false
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
    
    @ApiCallActor func makeReservationAsync (_ token: String, _ userId: Int, pmtId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                
                struct NewAgreementRequest: Encodable {
                    let vehicleId: Int
                    let startTime: Int
                    let endTime: Int
                    let paymentId: Int
                    let liability: Bool
                    let pcdw: Bool
                    let pcdwExt: Bool
                    let rsa: Bool
                    let pai: Bool
                    let rateOfferId: Int
                    @CodableExplicitNull var mileagePackageId: Int?
                    @CodableExplicitNull var promoCode: String?
                    let hoursUsingReward: FlexDecimal
                }
                
                let requestBody = NewAgreementRequest(vehicleId: vehicle.id, startTime: Int(startDate.timeIntervalSince1970), endTime: Int(endDate.timeIntervalSince1970), paymentId: pmtId, liability: false, pcdw: false, pcdwExt: false, rsa: false, pai: false, rateOfferId: rateOffer.id, mileagePackageId: mileagePackage?.id ?? nil, promoCode: promo?.code ?? nil, hoursUsingReward: FlexDecimal(Decimal(0)))
                
                let jsonData: Data = try VeygoJsonStandard.shared.encoder.encode(requestBody)
                
                let request = veygoCurlRequest(
                    url: "/api/v1/agreement/new",
                    method: .post,
                    headers: [
                        "auth": "\(token)$\(userId)"
                    ],
                    body: jsonData
                )
                await MainActor.run {
                    isCreatingAgreement = true
                }
                let (data, response) = try await URLSession.shared.data(for: request)
                
                await MainActor.run {
                    isCreatingAgreement = false
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
                    await MainActor.run {
                        alertTitle = "Server Error"
                        alertMessage = "Invalid content"
                        showAlert = true
                    }
                    return .doNothing
                }
                
                switch httpResponse.statusCode {
                    
                case 201:
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(Agreement.self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        alertTitle = "Booking Successful"
                        alertMessage = "Your confirmation number is \(decodedBody.confirmation)."
                        returnHomeTriggered = true
                        showAlert = true
                    }
                    return .doNothing
                case 400:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            returnHomeTriggered = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E400
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            returnHomeTriggered = true
                        }
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
                case 403:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E403
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    }
                    return .doNothing
                case 402:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E402
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                        }
                    }
                    return .doNothing
                case 409:
                    if let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data) {
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            returnHomeTriggered = true
                        }
                    } else {
                        let decodedBody = ErrorResponse.E409
                        await MainActor.run {
                            alertTitle = decodedBody.title
                            alertMessage = decodedBody.message
                            showAlert = true
                            returnHomeTriggered = true
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

private struct SelectPaymentCardView: View {
    
    @EnvironmentObject var session: UserSession
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @Binding var paymentMethods: [PublishPaymentMethod]
    @Binding var selectedPaymentMethod: PublishPaymentMethod?
    
    @State private var isAddingNewCard: Bool = false
    
    var body: some View {
        VStack {
            List {
                if paymentMethods.isEmpty {
                    Text("No payment cards available.")
                        .foregroundStyle(Color.footNote)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.mainBG)
                } else {
                    ForEach(paymentMethods) { card in
                        Button {
                            selectedPaymentMethod = card
                            dismiss()
                        } label: {
                            HStack(spacing: 16) {
                                cardBrandImage(for: card.network)
                                    .frame(width: 48, height: 48)
                                    .cornerRadius(4)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.nickname ?? card.maskedCardNumber)
                                        .foregroundStyle(Color.textBlackPrimary)
                                        .font(.headline)
                                    Text("Exp: \(card.expiration)")
                                        .foregroundStyle(Color.footNote)
                                        .font(.subheadline)
                                }
                                
                                Spacer()
                                
                                if selectedPaymentMethod?.id == card.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.primaryButtonBg)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.mainBG)
                    }
                }
            }
            .listStyle(.plain)
            .onChange(of: isAddingNewCard, { oldValue, newValue in
                if !newValue {
                    Task {
                        await ApiCallActor.shared.appendApi { token, userId in
                            await loadCardsAsync(token, userId)
                        }
                    }
                }
            })
            PrimaryButton(text: "Add a New Card") {
                isAddingNewCard = true
            }
            .padding()
            .sheet(isPresented: $isAddingNewCard) {
                FullStripeCardEntryView()
            }

        }
        .navigationTitle("Select Payment Card")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.mainBG, ignoresSafeAreaEdges: .all)
    }
    
    @ApiCallActor func loadCardsAsync (_ token: String, _ userId: Int) async -> ApiTaskResponse {
        do {
            let user = await MainActor.run { self.session.user }
            if !token.isEmpty && userId > 0, user != nil {
                let request = veygoCurlRequest(
                    url: "/api/v1/payment-method/get",
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
                    guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode([PublishPaymentMethod].self, from: data) else {
                        await MainActor.run {
                            alertTitle = "Server Error"
                            alertMessage = "Invalid content"
                            showAlert = true
                        }
                        return .doNothing
                    }
                    await MainActor.run {
                        self.paymentMethods = decodedBody
                        if let selectedPaymentMethod,
                           !decodedBody.contains(where: { $0.id == selectedPaymentMethod.id }) {
                            self.selectedPaymentMethod = decodedBody.first
                        } else if self.selectedPaymentMethod == nil {
                            self.selectedPaymentMethod = decodedBody.first
                        }
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
