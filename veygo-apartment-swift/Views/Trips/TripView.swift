//
//  TripView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/13/26.
//

import SwiftUI
import MapKit

struct TripView: View {
    @Environment(Session.self) private var session

    @State private var upcomingReservations: [TripInfo] = []

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    @State private var isLoading: Bool = true

    @Binding var selectedTab: RootDestination

    var body: some View {
        // Tab root — no inner NavigationStack; AppView owns the outer stack.
        Group {
            if session.renter != nil {
                tripList
            } else {
                EmptyView()
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    @ViewBuilder
    private var tripList: some View {
        List {
            NavigationLink {
                HistoryView()
            } label: {
                HStack {
                    Text("History and Receipts")
                        .foregroundStyle(Color.accentColor)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.accentColor)
                }
                .padding()
                .background(Color.cardBG)
                .cornerRadius(12)
            }
            .navigationLinkIndicatorVisibility(.hidden)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.mainBG)

            if upcomingReservations.isEmpty {
                VStack(alignment: .center, spacing: 16) {
                    Text("Want to start a new reservation?")
                        .foregroundStyle(Color.textBlackPrimary)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    PrimaryButton(text: "Make a reservation") {
                        selectedTab = .home
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 22)
                .overlay {
                    if isLoading {
                        LoadingView().cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.footNote.opacity(0.5), lineWidth: 1)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.mainBG)
            } else {
                Text("Your Upcoming \(upcomingReservations.count == 1 ? "Trip" : "Trips")")
                    .font(.title)
                    .fontWeight(.bold)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.mainBG)
                ForEach(upcomingReservations) { rsvp in
                    GlassEffectContainer {
                        NavigationLink {
                            UpcomingReservationDetailedView(rsvp: rsvp.agreement)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("RSVP")
                                            .fontWeight(.bold)
                                            .foregroundStyle(Color.textBlackPrimary)
                                        Text("#\(rsvp.agreement.confirmation)")
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color.textLink)
                                    }
                                    Text("\(rsvp.localizedStartDate())")
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.textBlackSecondary)
                                    Text("Location: \(rsvp.locationName)")
                                        .font(.callout)
                                        .foregroundStyle(Color.textBlackSecondary)
                                    Text("Vehicle: \(rsvp.vehicleName)")
                                        .font(.callout)
                                        .foregroundStyle(Color.textBlackSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color.accentColor)
                            }
                            .padding()
                            .background(Color.cardBG, ignoresSafeAreaEdges: .all)
                            .cornerRadius(12)
                            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                        }
                        .navigationLinkIndicatorVisibility(.hidden)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.mainBG)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .background(Color.mainBG, ignoresSafeAreaEdges: .all)
        .navigationTitle(Text("Trips"))
        .task {
            await loadUpcoming()
        }
        .refreshable {
            await loadUpcoming()
        }
    }

    // MARK: - Load upcoming

    private func loadUpcoming() async {
        do {
            let trips = try await fetchUpcoming()
            upcomingReservations = trips
            isLoading = false
        } catch let error as VeygoError {
            isLoading = false
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            isLoading = false
            present(.E_DEFAULT)
        }
    }

    private func fetchUpcoming() async throws -> [TripInfo] {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unknown
        }

        isLoading = true
        let request = veygoCurlRequest(
            url: "/api/v1/agreement/upcoming",
            method: .get,
            headers: ["auth": "\(token)$\(userId)"]
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return try VeygoJsonStandard.shared.decoder.decode([TripInfo].self, from: data)
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.unauthorized(decodedError)
            } else {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
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

private struct UpcomingReservationDetailedView: View {
    @Environment(Session.self) private var session

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    @State private var details: TripDetailedInfo?

    let rsvp: Agreement

    private var rawDuration: TimeInterval {
        guard let details else { return 0 }
        return max(0, details.agreement.rsvpDropOffTime.timeIntervalSince(details.agreement.rsvpPickupTime))
    }

    private var hourlyRate: Decimal {
        guard let details else { return Decimal.zero }
        return details.agreement.msrpFactor.value
            * details.agreement.durationRate.value
            * details.agreement.utilizationFactor.value
    }

    private var pricingStandard: VeygoPricingStandard? {
        guard let details else { return nil }
        return VeygoPricingStandard(apartment: details.apartment, vehicle: details.vehicle)
    }

    private var rawHours: Decimal {
        Decimal(rawDuration) / Decimal(3600)
    }

    private var totalHoursReservedRoundedUp: Decimal {
        guard rawHours > 0 else { return Decimal.zero }
        return NSDecimalNumber(decimal: rawHours).rounding(accordingToBehavior: NSDecimalNumberHandler(
            roundingMode: .up,
            scale: 0,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )).decimalValue
    }

    private var totalHoursReservedRoundedUpInt: Int {
        NSDecimalNumber(decimal: totalHoursReservedRoundedUp).intValue
    }

    private var rewardHoursUsed: Decimal {
        guard let details else { return Decimal.zero }
        return details.rewardTransactions.reduce(Decimal.zero) { partial, transaction in
            let duration = transaction.duration.value
            guard duration > Decimal.zero else { return partial }
            return partial + duration
        }
    }

    private var billableDaysCount: Int {
        pricingStandard?.billableDaysCount(rawDuration: rawDuration) ?? 0
    }

    private var billableDurationHours: Decimal {
        pricingStandard?.calculateBillableDurationHours(rawDuration: rawDuration) ?? Decimal.zero
    }

    private var tripSubtotalBeforeReward: Decimal {
        billableDurationHours * hourlyRate
    }

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

    private var insuranceHourlyRate: Decimal {
        guard let details else { return Decimal.zero }
        return (details.agreement.liabilityProtectionRate?.value ?? Decimal.zero)
            + (details.agreement.pcdwProtectionRate?.value ?? Decimal.zero)
            + (details.agreement.pcdwExtProtectionRate?.value ?? Decimal.zero)
            + (details.agreement.rsaProtectionRate?.value ?? Decimal.zero)
            + (details.agreement.paiProtectionRate?.value ?? Decimal.zero)
    }

    private var insuranceSubtotal: Decimal {
        totalHoursReservedRoundedUp * insuranceHourlyRate
    }

    private var tripTotalHours: Decimal {
        rawHours
    }

    private var averageHourlyRate: Decimal {
        guard tripTotalHours > 0 else { return Decimal.zero }
        return tripSubtotal / tripTotalHours
    }

    private var mileageSubtotal: Decimal {
        guard let details, let pkg = details.mileagePackage else { return Decimal.zero }
        let standard = VeygoPricingStandard(apartment: details.apartment, vehicle: details.vehicle)
        return standard.mileagePackagePrice(for: pkg)
    }

    private var subtotalBeforeDiscount: Decimal {
        tripSubtotal + insuranceSubtotal + mileageSubtotal
    }

    private var promoDiscount: Decimal {
        min(details?.promo?.amount.value ?? Decimal.zero, subtotalBeforeDiscount)
    }

    private var subtotalBeforeTax: Decimal {
        max(Decimal.zero, subtotalBeforeDiscount - promoDiscount)
    }

    private var applicableTaxes: [Tax] {
        (details?.taxes ?? []).filter { tax in
            if let threshold = tax.threshold, let isLower = tax.isLower {
                if isLower {
                    return totalHoursReservedRoundedUpInt < threshold
                } else {
                    return totalHoursReservedRoundedUpInt >= threshold
                }
            } else {
                return true
            }
        }
    }

    private var certainTaxesNeededToApplySalesTax: Decimal {
        applicableTaxes.reduce(Decimal.zero) { partial, tax in
            guard tax.isSalesTax else { return partial }
            switch tax.taxType {
            case .daily:
                return partial + (Decimal(billableDaysCount) * tax.multiplier.value)
            case .fixed:
                return partial + tax.multiplier.value
            case .percent:
                return partial
            }
        }
    }

    private var totalSubjectToSalesTax: Decimal {
        subtotalBeforeTax + certainTaxesNeededToApplySalesTax
    }

    private var taxLines: [TaxLine] {
        applicableTaxes.map { tax in
            let amount: Decimal
            switch tax.taxType {
            case .percent:
                let taxBase = tax.isSalesTax ? totalSubjectToSalesTax : subtotalBeforeTax
                amount = taxBase * normalizedPercentMultiplier(tax.multiplier.value)
            case .daily:
                amount = Decimal(billableDaysCount) * tax.multiplier.value
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
        Group {
            if session.renter != nil {
                content
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        List {
            if let details = details {
                loadedContent(details: details)
            } else {
                placeholderContent
            }
        }
        .frame(maxWidth: .infinity)
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .background(Color.mainBG, ignoresSafeAreaEdges: .all)
        .navigationTitle(Text("Trip Summary"))
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .task {
            await loadDetails()
        }
    }

    @ViewBuilder
    private func loadedContent(details: TripDetailedInfo) -> some View {
        HStack {
            Text("Confirmation #:")
                .foregroundStyle(Color.textBlackSecondary)
                .font(.subheadline)
            Text("\(rsvp.confirmation)")
                .foregroundStyle(Color.accent)
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)
        Image(.tempVehicle)
            .resizable()
            .scaledToFill()
            .frame(width: 300, height: 130)
            .clipped()
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.mainBG)
        VStack(alignment: .leading, spacing: 16) {
            Text("\(details.vehicle.make) \(details.vehicle.model)")
                .foregroundStyle(Color.textBlackSecondary)
                .font(.title3)
                .fontWeight(.bold)
            Text("\(details.vehicle.licenseState) \(details.vehicle.licenseNumber) \(details.vehicle.name)")
                .foregroundStyle(Color.textBlackPrimary)
                .font(.subheadline)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)

        VStack(alignment: .leading, spacing: 16) {
            Text("Itinerary")
                .foregroundStyle(Color.textBlackSecondary)
                .font(.title2)
                .fontWeight(.bold)
            HStack {
                Image(systemName: "location.fill")
                    .foregroundStyle(Color.accent)
                Text("\(details.apartment.name) - \(details.location.name)")
                    .foregroundStyle(Color.textBlackPrimary)
            }
            .font(.subheadline)
            HStack {
                Image(systemName: "clock.badge.fill")
                    .foregroundStyle(Color.textLink)
                Text("\(details.localizedStartDate())")
                    .foregroundStyle(Color.textBlackPrimary)
            }
            .font(.subheadline)
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(Color.textLink)
                Text("\(details.localizedEndDate())")
                    .foregroundStyle(Color.textBlackPrimary)
            }
            .font(.subheadline)
            Map(
                initialPosition: .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(
                            latitude: details.location.latitude,
                            longitude: details.location.longitude
                        ),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                ),
                interactionModes: []
            ) {
                Marker(
                    "Pickup Location",
                    coordinate: CLLocationCoordinate2D(
                        latitude: details.location.latitude,
                        longitude: details.location.longitude
                    )
                ).tint(.purple)
            }
            .frame(height: 160)
            .cornerRadius(16)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)

        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Info")
                .foregroundStyle(Color.textBlackSecondary)
                .font(.title2)
                .fontWeight(.bold)
            HStack(spacing: 16) {
                cardBrandImage(for: details.paymentMethod.network)
                    .frame(width: 64, height: 64)
                    .cornerRadius(4)
                VStack(alignment: .leading, spacing: 4) {
                    Text(details.paymentMethod.nickname ?? details.paymentMethod.maskedCardNumber)
                        .foregroundStyle(Color.textBlackPrimary)
                    Text("Expires: \(details.paymentMethod.expiration)")
                        .foregroundStyle(Color.textBlackSecondary)
                }
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)
        VStack(alignment: .leading, spacing: 16) {
            Text("Price Details")
                .foregroundStyle(Color.textBlackSecondary)
                .font(.title2)
                .fontWeight(.bold)
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
                    priceLine(
                        title: "Promo (\(details.promo?.code ?? ""))",
                        value: "-\(formatRate(promoDiscount))"
                    )
                    Divider()
                }
                if mileageSubtotal > 0 {
                    priceLine(
                        title: "Mileage package (\(10 + (details.mileagePackage?.miles ?? 0)) miles)",
                        value: formatRate(mileageSubtotal)
                    )
                    Divider()
                }
                if insuranceSubtotal > 0 {
                    priceLine(
                        title: "Insurance options",
                        value: formatRate(insuranceSubtotal)
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
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)
        HStack {
            Image(systemName: "xmark")
                .fontWeight(.semibold)
                .foregroundStyle(Color.dangerButtonText)
            Text("Cancel Reservation")
                .foregroundStyle(Color.dangerButtonText)
                .underline()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)
    }

    @ViewBuilder
    private var placeholderContent: some View {
        HStack {
            Text("Confirmation #:")
                .foregroundStyle(Color.textBlackSecondary)
                .font(.subheadline)
            Text("ABDC-1234")
                .foregroundStyle(Color.clear)
                .font(.subheadline)
                .fontWeight(.bold)
                .overlay { LoadingView().cornerRadius(16) }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)
        Image(.tempVehicle)
            .resizable()
            .scaledToFill()
            .frame(width: 300, height: 130)
            .clipped()
            .overlay { LoadingView().cornerRadius(16) }
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.mainBG)
        VStack(alignment: .leading, spacing: 16) {
            Text("Tesla Model 3")
                .foregroundStyle(Color.clear)
                .font(.title3)
                .fontWeight(.bold)
                .overlay { LoadingView().cornerRadius(16) }
            Text("IN ABC123 The Veygo Car")
                .foregroundStyle(Color.clear)
                .font(.subheadline)
                .overlay { LoadingView().cornerRadius(16) }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)
        VStack(alignment: .leading, spacing: 16) {
            Text("Itinerary")
                .foregroundStyle(Color.textBlackSecondary)
                .font(.title2)
                .fontWeight(.bold)
            HStack {
                Image(systemName: "location.fill").foregroundStyle(Color.clear)
                Text("Veygo HQ - Main Campus").foregroundStyle(Color.clear)
            }
            .font(.subheadline)
            .overlay { LoadingView().cornerRadius(16) }
            HStack {
                Image(systemName: "clock.badge.fill").foregroundStyle(Color.clear)
                Text("Dec 22, 2022 at 10:30PM").foregroundStyle(Color.clear)
            }
            .font(.subheadline)
            .overlay { LoadingView().cornerRadius(16) }
            HStack {
                Image(systemName: "clock.fill").foregroundStyle(Color.clear)
                Text("Dec 22, 2077 at 10:30PM").foregroundStyle(Color.clear)
            }
            .font(.subheadline)
            .overlay { LoadingView().cornerRadius(16) }
            Map(interactionModes: []) { }
                .frame(height: 160)
                .cornerRadius(16)
                .overlay { LoadingView().cornerRadius(16) }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)

        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Info")
                .foregroundStyle(Color.textBlackSecondary)
                .font(.title2)
                .fontWeight(.bold)
            HStack(spacing: 16) {
                cardBrandImage(for: "amex")
                    .frame(width: 64, height: 64)
                    .cornerRadius(4)
                    .overlay { LoadingView().cornerRadius(4) }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Veygo Billing")
                        .foregroundStyle(Color.clear)
                        .overlay { LoadingView().cornerRadius(16) }
                    Text("Expires: 12/2077")
                        .foregroundStyle(Color.clear)
                        .overlay { LoadingView().cornerRadius(16) }
                }
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)
        VStack(spacing: 12) {
            HStack {
                Text("Total est.")
                    .fontWeight(.bold)
                    .foregroundStyle(Color.clear)
                Spacer()
                Text("$52.39")
                    .fontWeight(.bold)
                    .foregroundStyle(Color.clear)
            }
            .padding()
            .background(Color.cardBG)
            .cornerRadius(16)
            .overlay { LoadingView().cornerRadius(16) }
            Text("Price Details")
                .font(.system(size: 15, weight: .regular, design: .default))
                .foregroundStyle(Color.clear)
                .underline()
                .overlay { LoadingView().cornerRadius(16) }
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Estimated total does not include any fuel charges, tolls, or any other fees that may occur during your trip (taxes and fees may apply).")
                .foregroundStyle(Color.clear)
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay { LoadingView().cornerRadius(16) }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)
        HStack {
            Image(systemName: "xmark")
                .fontWeight(.semibold)
                .foregroundStyle(Color.dangerButtonText)
            Text("Cancel Reservation")
                .foregroundStyle(Color.dangerButtonText)
                .underline()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .overlay { LoadingView().cornerRadius(16) }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.mainBG)
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

    // MARK: - Load details

    private func loadDetails() async {
        do {
            let loaded = try await fetchDetails()
            details = loaded
        } catch let error as VeygoError {
            if case .unauthorized = error { session.clear() }
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func fetchDetails() async throws -> TripDetailedInfo {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unknown
        }

        let request = veygoCurlRequest(
            url: "/api/v1/agreement/\(rsvp.confirmation)",
            method: .get,
            headers: ["auth": "\(token)$\(userId)"]
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return try VeygoJsonStandard.shared.decoder.decode(TripDetailedInfo.self, from: data)
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.unauthorized(decodedError)
            } else {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
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
