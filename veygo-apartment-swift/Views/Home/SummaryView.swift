//
//  SummaryView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/7/26.
//

import SwiftUI
import MapKit

struct SummaryView: View {
    @Environment(Session.self) private var session
    @Environment(Router.self) private var router

    @State private var paymentMethods: [PublishPaymentMethod] = []
    @State private var selectedPaymentMethod: PublishPaymentMethod?

    @State private var isLoadingPM: Bool = false
    @State private var isLoadingRewardHours: Bool = false
    @State private var isCreatingAgreement: Bool = false
    @State private var rewardHoursSummary: RewardHoursSummaryResponse? = nil
    @State private var rewardHoursUsedValue: Double = 0

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var returnHomeOnDismiss: Bool = false

    // Carried in from HomeDestination.summary.
    let startDate: Date
    let endDate: Date
    let vehicle: PublishRenterVehicle
    let apartment: Apartment
    let location: Location
    let promo: PublishPromo?
    let mileagePackage: MileagePackage?
    let taxes: [Tax]
    let rateOffer: RateOffer

    private var pricingStandard: VeygoPricingStandard {
        VeygoPricingStandard(apartment: apartment, vehicle: vehicle)
    }

    // MARK: - Pricing

    private var rawDuration: TimeInterval { max(0, endDate.timeIntervalSince(startDate)) }

    private var hourlyRate: Decimal {
        vehicle.msrpFactor.value * apartment.durationRate.value * rateOffer.multiplier.value
    }

    private var rawHours: Decimal { Decimal(rawDuration) / Decimal(3600) }

    private var rewardHoursUsed: Decimal {
        Decimal(min(max(rewardHoursUsedValue, 0), maxRewardHoursUsableDouble))
    }

    private var rewardHoursRemaining: Decimal {
        guard let rewardHoursSummary else { return Decimal.zero }
        return max(Decimal.zero, rewardHoursSummary.total.value - rewardHoursSummary.used.value)
    }

    private var maxRewardHoursUsable: Decimal { min(rawHours, rewardHoursRemaining) }

    private var maxRewardHoursUsableDouble: Double {
        NSDecimalNumber(decimal: maxRewardHoursUsable).doubleValue
    }

    private var tripTotalHours: Decimal { rawHours }

    private var billableDurationHours: Decimal {
        pricingStandard.calculateBillableDurationHours(rawDuration: rawDuration)
    }

    private var tripSubtotalBeforeReward: Decimal { billableDurationHours * hourlyRate }

    private var averageReservedHourRate: Decimal {
        guard rawHours > 0 else { return Decimal.zero }
        return tripSubtotalBeforeReward / rawHours
    }

    private var rewardDiscountAmount: Decimal {
        min(tripSubtotalBeforeReward, max(Decimal.zero, averageReservedHourRate * rewardHoursUsed))
    }

    private var tripSubtotal: Decimal {
        max(Decimal.zero, tripSubtotalBeforeReward - rewardDiscountAmount)
    }

    private var averageHourlyRate: Decimal {
        guard tripTotalHours > 0 else { return Decimal.zero }
        return tripSubtotal / tripTotalHours
    }

    // Insurance options are not selectable on this screen yet.
    private var selectedLiability: Bool { false }
    private var selectedPcdw: Bool { false }
    private var selectedPcdwExt: Bool { false }
    private var selectedRsa: Bool { false }
    private var selectedPai: Bool { false }

    private var totalHoursReservedRoundedUp: Decimal {
        guard rawHours > 0 else { return Decimal.zero }
        return NSDecimalNumber(decimal: rawHours).rounding(accordingToBehavior: NSDecimalNumberHandler(
            roundingMode: .up, scale: 0,
            raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false
        )).decimalValue
    }

    private var totalHoursReservedRoundedUpInt: Int {
        NSDecimalNumber(decimal: totalHoursReservedRoundedUp).intValue
    }

    private var selectedInsuranceHourlyRate: Decimal {
        var total = Decimal.zero
        if selectedLiability { total += apartment.liabilityProtectionRate?.value ?? Decimal.zero }
        if selectedPcdw      { total += apartment.pcdwProtectionRate?.value ?? Decimal.zero }
        if selectedPcdwExt   { total += apartment.pcdwExtProtectionRate?.value ?? Decimal.zero }
        if selectedRsa       { total += apartment.rsaProtectionRate?.value ?? Decimal.zero }
        if selectedPai       { total += apartment.paiProtectionRate?.value ?? Decimal.zero }
        return total
    }

    private var insuranceSubtotal: Decimal { totalHoursReservedRoundedUp * selectedInsuranceHourlyRate }

    private var mileageSubtotal: Decimal {
        guard let mileagePackage else { return Decimal.zero }
        return pricingStandard.mileagePackagePrice(for: mileagePackage)
    }

    private var discounts: PricingDiscounts {
        PricingDiscounts(
            durationSubtotal: tripSubtotal,
            mileageSubtotal: mileageSubtotal,
            insuranceSubtotal: insuranceSubtotal,
            promoAmount: promo?.amount.value ?? .zero
        )
    }

    private var promoDiscount: Decimal { discounts.promoDiscount }

    private var subtotalBeforeTax: Decimal { discounts.subtotalBeforeTax }

    private var billableDaysCount: Int { pricingStandard.billableDaysCount(rawDuration: rawDuration) }

    private var applicableTaxes: [Tax] {
        taxes.filter { tax in
            if let threshold = tax.threshold, let isLower = tax.isLower {
                return isLower ? totalHoursReservedRoundedUpInt < threshold
                               : totalHoursReservedRoundedUpInt >= threshold
            }
            return true
        }
    }

    private var certainTaxesNeededToApplySalesTax: Decimal {
        applicableTaxes.reduce(Decimal.zero) { partial, tax in
            guard tax.isSalesTax else { return partial }
            switch tax.taxType {
            case .daily:   return partial + (Decimal(billableDaysCount) * tax.multiplier.value)
            case .fixed:   return partial + tax.multiplier.value
            case .percent: return partial
            }
        }
    }

    private var totalSubjectToSalesTax: Decimal { subtotalBeforeTax + certainTaxesNeededToApplySalesTax }

    private var taxLines: [TaxLine] {
        applicableTaxes.map { tax in
            let amount: Decimal
            switch tax.taxType {
            case .percent:
                let base = tax.isSalesTax ? totalSubjectToSalesTax : subtotalBeforeTax
                amount = base * normalizedPercentMultiplier(tax.multiplier.value)
            case .daily:
                amount = Decimal(billableDaysCount) * tax.multiplier.value
            case .fixed:
                amount = tax.multiplier.value
            }
            return TaxLine(id: tax.id, name: tax.name, amount: amount)
        }
    }

    private var totalTax: Decimal { taxLines.reduce(Decimal.zero) { $0 + $1.amount } }

    private var finalEstimatedTotal: Decimal { subtotalBeforeTax + totalTax }

    private func normalizedPercentMultiplier(_ multiplier: Decimal) -> Decimal {
        let absolute = multiplier < 0 ? -multiplier : multiplier
        return absolute > Decimal(1) ? multiplier / Decimal(100) : multiplier
    }

    // MARK: - Body

    var body: some View {
        Group {
            if session.renter != nil {
                content
            } else {
                EmptyView()
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .frame(maxWidth: .infinity)
        .navigationTitle(Text("Trip Summary"))
        .background(Color.mainBG, ignoresSafeAreaEdges: .all)
    }

    @ViewBuilder
    private var content: some View {
        GlassEffectContainer {
            ZStack(alignment: .bottom) {
                List {
                    Image(.tempVehicle)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 130)
                        .clipped()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.mainBG)

                    vehicleSection
                    itinerarySection
                    mileageSection
                    paymentSection
                    priceSection
                }
                .scrollIndicators(.hidden)
                .listStyle(.plain)

                PrimaryButton(text: "Book Trip") {
                    if let paymentMethodId = selectedPaymentMethod?.id {
                        Task { await bookTrip(paymentMethodId: paymentMethodId) }
                    }
                }
                .disabled(selectedPaymentMethod == nil || isCreatingAgreement)
                .padding()
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if returnHomeOnDismiss {
                    router.popToRoot()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .task {
            await loadCards()
            await loadRewardHours()
        }
    }

    // MARK: - Sections

    private var vehicleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
    }

    private var itinerarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Itinerary")
                .foregroundStyle(Color.textBlackSecondary)
                .font(.title2)
                .fontWeight(.bold)
            HStack {
                Image(systemName: "location.fill").foregroundStyle(Color.accent)
                Text("\(apartment.name) - \(location.name)").foregroundStyle(Color.textBlackPrimary)
            }
            .font(.subheadline)
            HStack {
                Image(systemName: "clock.badge.fill").foregroundStyle(Color.textLink)
                Text(apartment.localizedDate(for: startDate)).foregroundStyle(Color.textBlackPrimary)
            }
            .font(.subheadline)
            HStack {
                Image(systemName: "clock.fill").foregroundStyle(Color.textLink)
                Text(apartment.localizedDate(for: endDate)).foregroundStyle(Color.textBlackPrimary)
            }
            .font(.subheadline)
            Map(
                initialPosition: .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )),
                interactionModes: []
            ) {
                Marker("Pickup Location",
                       coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                    .tint(.purple)
            }
            .frame(height: 160)
            .cornerRadius(16)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)
    }

    private var mileageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mileage Option")
                .foregroundStyle(Color.textBlackSecondary)
                .font(.title2)
                .fontWeight(.bold)
            HStack {
                Image(systemName: "map.fill").foregroundStyle(Color.accent)
                Text("^[Included distance: \(10 + (mileagePackage?.miles ?? 0)) mile](inflect: true)")
                    .foregroundStyle(Color.textBlackPrimary)
            }
            .font(.subheadline)
            HStack {
                Image(systemName: "dollarsign.circle.fill").foregroundStyle(Color.textLink)
                Text(pricingStandard.perMileSubtitle()).foregroundStyle(Color.textBlackPrimary)
            }
            .font(.subheadline)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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

                    Image(systemName: "chevron.right").foregroundStyle(Color.footNote)
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
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Price Details")
                .foregroundStyle(Color.textBlackSecondary)
                .font(.title2)
                .fontWeight(.bold)

            if isLoadingRewardHours {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Loading reward hours...")
                        .foregroundStyle(Color.footNote)
                        .font(.footnote)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if maxRewardHoursUsable > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Use reward hours")
                            .foregroundStyle(Color.textBlackPrimary)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(formatHourNumber(rewardHoursUsed)) / \(formatHourNumber(maxRewardHoursUsable)) hr")
                            .foregroundStyle(Color.footNote)
                            .font(.footnote)
                    }
                    Slider(
                        value: Binding(
                            get: { min(max(rewardHoursUsedValue, 0), maxRewardHoursUsableDouble) },
                            set: { rewardHoursUsedValue = min(max($0, 0), maxRewardHoursUsableDouble) }
                        ),
                        in: 0...maxRewardHoursUsableDouble,
                        step: min(0.25, maxRewardHoursUsableDouble)
                    )
                }
                .padding()
                .background(Color.cardBG)
                .cornerRadius(12)
            }

            VStack(spacing: 10) {
                priceLine(
                    title: "\(formatHours(tripTotalHours)) @ \(formatRate(averageReservedHourRate))/hr",
                    value: formatRate(tripSubtotalBeforeReward)
                )
                if rewardDiscountAmount > 0 {
                    priceLine(
                        title: "Reward hours used (\(formatHourNumber(rewardHoursUsed)) hr)",
                        value: "-\(formatRate(rewardDiscountAmount))"
                    )
                }
                Divider()
                if promoDiscount > 0 {
                    priceLine(title: "Promo (\(promo?.code ?? ""))", value: "-\(formatRate(promoDiscount))")
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
                        priceLine(title: taxLine.name, value: formatRate(taxLine.amount))
                    }
                }
                Divider()
                priceLine(title: "Final total est.", value: formatRate(finalEstimatedTotal), weight: .bold)
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
                ("Rental Terms", { router.push(HomeDestination.rentalTerms) })
            ])
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)
        .padding(.bottom, 80)
    }

    // MARK: - Formatting

    @ViewBuilder
    private func priceLine(title: String, value: String, weight: Font.Weight = .regular) -> some View {
        HStack {
            Text(title).foregroundStyle(Color.textBlackPrimary).fontWeight(weight)
            Spacer()
            Text(value).foregroundStyle(Color.textBlackPrimary).fontWeight(weight)
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
                    roundingMode: .down, scale: 0,
                    raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false
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

    // MARK: - Cards

    private func loadCards() async {
        isLoadingPM = true
        defer { isLoadingPM = false }
        do {
            let cards = try await fetchPaymentMethods(session: session)
            paymentMethods = cards
            if let selectedPaymentMethod, !cards.contains(where: { $0.id == selectedPaymentMethod.id }) {
                self.selectedPaymentMethod = cards.first
            } else if selectedPaymentMethod == nil {
                selectedPaymentMethod = cards.first
            }
        } catch let error as VeygoError {
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    // MARK: - Reward hours

    private func loadRewardHours() async {
        isLoadingRewardHours = true
        defer { isLoadingRewardHours = false }
        do {
            let summary = try await fetchRewardHours()
            rewardHoursSummary = summary
            rewardHoursUsedValue = min(rewardHoursUsedValue, maxRewardHoursUsableDouble)
        } catch let error as VeygoError {
            if case .unauthorized = error {
                session.clear()
                present(error.display)
            }
            // Other reward-hour failures are non-fatal (original was silent).
        } catch {
            // ignore
        }
    }

    private func fetchRewardHours() async throws -> RewardHoursSummaryResponse {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else { throw VeygoError.unknown }

        let request = veygoCurlRequest(
            url: "/api/v1/user/reward-hour",
            method: .get,
            headers: ["auth": "\(token)$\(userId)"]
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw VeygoError.unknown }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return try VeygoJsonStandard.shared.decoder.decode(RewardHoursSummaryResponse.self, from: data)
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

    // MARK: - Book

    private func bookTrip(paymentMethodId: Int) async {
        isCreatingAgreement = true
        defer { isCreatingAgreement = false }

        do {
            let agreement = try await createAgreement(paymentMethodId: paymentMethodId)
            present(title: "Booking Successful",
                    message: "Your confirmation number is \(agreement.confirmation).",
                    returnHome: true)
        } catch let error as VeygoError {
            switch error {
            case .unauthorized:
                session.clear()
                present(error.display)
            case .server(let status, _) where status == 400 || status == 409:
                present(error.display, returnHome: true)   // bad request / conflict → back to Home
            default:
                present(error.display)                     // 402 / 403 / others → stay
            }
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func createAgreement(paymentMethodId: Int) async throws -> Agreement {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else { throw VeygoError.unknown }

        let body = NewAgreementRequest(
            vehicleId: vehicle.id,
            startTime: Int(startDate.timeIntervalSince1970),
            endTime: Int(endDate.timeIntervalSince1970),
            paymentId: paymentMethodId,
            liability: selectedLiability,
            pcdw: selectedPcdw,
            pcdwExt: selectedPcdwExt,
            rsa: selectedRsa,
            pai: selectedPai,
            rateOfferId: rateOffer.id,
            mileagePackageId: mileagePackage?.id,
            promoCode: promo?.code,
            hoursUsingReward: FlexDecimal(rewardHoursUsed)
        )
        let jsonData = try VeygoJsonStandard.shared.encoder.encode(body)
        let request = veygoCurlRequest(
            url: "/api/v1/agreement/new",
            method: .post,
            headers: ["auth": "\(token)$\(userId)"],
            body: jsonData
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw VeygoError.unknown }
            let httpCode = httpResponse.statusCode

            if httpCode == 201 {
                return try VeygoJsonStandard.shared.decoder.decode(Agreement.self, from: data)
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

    private func present(_ error: ErrorResponse, returnHome: Bool = false) {
        present(title: error.title, message: error.message, returnHome: returnHome)
    }

    private func present(title: String, message: String, returnHome: Bool = false) {
        alertTitle = title
        alertMessage = message
        returnHomeOnDismiss = returnHome
        showAlert = true
    }
}

// MARK: - Request body

private struct NewAgreementRequest: Encodable {
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
    var mileagePackageId: Int?
    var promoCode: String?
    let hoursUsingReward: FlexDecimal
}

// MARK: - Shared: fetch payment methods (SummaryView + SelectPaymentCardView)

@MainActor
private func fetchPaymentMethods(session: Session) async throws -> [PublishPaymentMethod] {
    let token = session.token
    let userId = session.userId
    guard !token.isEmpty, userId > 0 else { throw VeygoError.unknown }

    let request = veygoCurlRequest(
        url: "/api/v1/payment-method/get",
        method: .get,
        headers: ["auth": "\(token)$\(userId)"]
    )
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw VeygoError.unknown }
        let httpCode = httpResponse.statusCode

        if httpCode == 200 {
            return try VeygoJsonStandard.shared.decoder.decode([PublishPaymentMethod].self, from: data)
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

// MARK: - Select payment card

private struct SelectPaymentCardView: View {
    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss

    @Binding var paymentMethods: [PublishPaymentMethod]
    @Binding var selectedPaymentMethod: PublishPaymentMethod?

    @State private var isAddingNewCard: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

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

            PrimaryButton(text: "Add a New Card") {
                isAddingNewCard = true
            }
            .padding()
            .sheet(isPresented: $isAddingNewCard, onDismiss: {
                Task { await reloadCards() }
            }) {
                FullStripeCardEntryView()
            }
        }
        .navigationTitle("Select Payment Card")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.mainBG, ignoresSafeAreaEdges: .all)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    private func reloadCards() async {
        do {
            let cards = try await fetchPaymentMethods(session: session)
            paymentMethods = cards
            if let selectedPaymentMethod, !cards.contains(where: { $0.id == selectedPaymentMethod.id }) {
                self.selectedPaymentMethod = cards.first
            } else if selectedPaymentMethod == nil {
                selectedPaymentMethod = cards.first
            }
        } catch let error as VeygoError {
            if case .unauthorized = error { session.clear() }
            alertTitle = error.display.title
            alertMessage = error.display.message
            showAlert = true
        } catch {
            alertTitle = ErrorResponse.E_DEFAULT.title
            alertMessage = ErrorResponse.E_DEFAULT.message
            showAlert = true
        }
    }
}
