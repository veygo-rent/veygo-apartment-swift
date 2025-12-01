//
//  VehicleDetailView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/19/25.
//
//  Requires: VehicleWithBlockedDurations Struct, Start and End Time, Apartment Struct, Location Struct
//

import SwiftUI

struct VehicleDetailView: View {
    
    @EnvironmentObject var session: UserSession
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false
    
    @Binding var path: [HomeDestination]
    
    var startTime: Date
    var endTime: Date
    var apartment: Apartment
    var vehicleWithBlocksAndLocationInfo: (VehicleWithBlockedDurations, Location)
    
    // Protection option selections
    @State private var includeLiability = false
    @State private var includePCDW = false
    @State private var includePCDWExt = false
    @State private var includeRSA = false
    @State private var includePAI = false
    
    @State private var mileagePackageId: MileagePackage.ID? = nil
    @State private var mileagePackages: [MileagePackage] = []
    
    private enum MileageRowPosition {
        case single
        case first
        case middle
        case last
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack {
                    Image("VehicleShowroom")
                        .resizable()
                        .aspectRatio(1.3, contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    Image("TempVehicle")
                        .resizable()
                        .aspectRatio(1.25, contentMode: .fill)
                        .scaleEffect(0.8, anchor: .bottom)
                }
                VStack(spacing: 0) {
                    VStack(spacing: 18) {
                        Text(vehicleWithBlocksAndLocationInfo.0.vehicle.name)
                            .textCase(.uppercase)
                            .font(.title)
                            .fontWeight(.heavy)
                            .foregroundStyle(Color("TextBlackPrimary"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(vehicleWithBlocksAndLocationInfo.0.vehicle.year) \(vehicleWithBlocksAndLocationInfo.0.vehicle.make) \(vehicleWithBlocksAndLocationInfo.0.vehicle.model)")
                            .font(.callout)
                            .foregroundStyle(Color("FootNote"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Grid(alignment: .leading, verticalSpacing: 10) {
                            GridRow {
                                Image(systemName: "person.fill")
                                    .gridColumnAlignment(.center)
                                Text(vehicleWithBlocksAndLocationInfo.0.vehicle.capacity > 1 ? "\(vehicleWithBlocksAndLocationInfo.0.vehicle.capacity) People" : "1 Person")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 4)
                                Image(systemName: "car.top.arrowtriangle.rear.right.fill")
                                    .gridColumnAlignment(.center)
                                Text(vehicleWithBlocksAndLocationInfo.0.vehicle.doors > 1 ? "\(vehicleWithBlocksAndLocationInfo.0.vehicle.doors) Doors" : "1 Door")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 4)
                            }
                            GridRow {
                                Image(systemName: "suitcase.fill")
                                Text(vehicleWithBlocksAndLocationInfo.0.vehicle.smallBags > 1 ? "\(vehicleWithBlocksAndLocationInfo.0.vehicle.smallBags) Small Bags" : "1 Small Bag")
                                    .padding(.leading, 4)
                                Image(systemName: "suitcase.rolling.and.suitcase.fill")
                                Text(vehicleWithBlocksAndLocationInfo.0.vehicle.largeBags > 1 ? "\(vehicleWithBlocksAndLocationInfo.0.vehicle.largeBags) Big Bags" : "1 Big Bag")
                                    .padding(.leading, 4)
                            }
                            GridRow {
                                Image(systemName: "location.app.fill")
                                Text(vehicleWithBlocksAndLocationInfo.0.vehicle.carplay ? "Apple CarPlay" :"In Car Navigation")
                                    .padding(.leading, 4)
                                Image(systemName: vehicleWithBlocksAndLocationInfo.0.vehicle.laneKeep ? "car.rear.road.lane" : "gauge.open.with.lines.needle.67percent.and.arrowtriangle.and.car")
                                Text(vehicleWithBlocksAndLocationInfo.0.vehicle.laneKeep ? "Lane Keeping" : "Cruise Control")
                                    .padding(.leading, 4)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color("TextBlackSecondary"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(18)
                    .background(Color("CardBG"))
                    if vehicleWithBlocksAndLocationInfo.0.isVehicleAvailable(start: startTime, end: endTime) {
                        AvailableVehicle()
                    } else {
                        UnavailableVehicle()
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .swipeBackGesture {
            path.removeLast()
        }
        .scrollIndicators(.hidden)
        .background(Color("MainBG"))
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    path.removeLast()
                }) {
                    Image(systemName: "chevron.left")
                }
            }
        })
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(.container)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            Task {
                await ApiCallActor.shared.appendApi { token, userId in
                    await loadMilagePackageAsync()
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
    
    @ViewBuilder
    private func AvailableVehicle() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Mileage package section
            VStack(alignment: .leading, spacing: 12) {
                Text("Mileage package")
                    .font(.headline)
                    .foregroundStyle(Color("TextBlackPrimary"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 0) {
                    // Determine if there are any additional mileage packages
                    let hasPackages = !mileagePackages.isEmpty

                    // First option: no mileage package
                    MileagePackageRow(
                        title: "10 Miles Free",
                        subtitle: perMileSubtitle(),
                        trailingText: "Included",
                        isSelected: mileagePackageId == nil,
                        position: hasPackages ? .first : .single,
                        action: {
                            mileagePackageId = nil
                        }
                    )

                    // API-provided mileage packages
                    ForEach(Array(mileagePackages.enumerated()), id: \.element.id) { index, pkg in
                        let isLast = index == mileagePackages.count - 1
                        let position: MileageRowPosition = isLast ? .last : .middle

                        MileagePackageRow(
                            title: "\(10 + pkg.miles) Miles",
                            subtitle: perMileSubtitle(),
                            trailingText: formatRate(mileagePackagePrice(for: pkg, at: apartment)),
                            isSelected: mileagePackageId == pkg.id,
                            position: position,
                            action: {
                                mileagePackageId = pkg.id
                            }
                        )
                    }
                }
                PrimaryButtonLg(text: "Continue") {
                    // TODO
                }
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 6)

            Spacer(minLength: 24)
        }
        .padding(.top, 6)
    }

    private func formatRate(_ rate: Double) -> String {
        let number = NSNumber(value: rate)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: number) ?? "$\(String(format: "%.2f", rate))"
    }
    
    private func standardMileageRate() -> Double {
        if let overwrite = apartment.mileageRateOverwrite {
            return overwrite
        } else {
            let vehicle = vehicleWithBlocksAndLocationInfo.0.vehicle
            return vehicle.msrpFactor * apartment.durationRate * apartment.mileageConversion
        }
    }

    private func perMileSubtitle() -> String {
        let cents = Int((standardMileageRate() * 100).rounded())
        return "\(cents)\u{00a2} per mile afterwards"
    }

    private func mileagePackagePrice(for pkg: MileagePackage, at apt: Apartment) -> Double {
        let baseRate: Double
        if let overwrite = apartment.mileagePackageOverwrite {
            baseRate = overwrite
        } else {
            let vehicle = vehicleWithBlocksAndLocationInfo.0.vehicle
            baseRate = vehicle.msrpFactor * apartment.durationRate * apt.mileageConversion
        }
        return baseRate * Double(pkg.miles) * (Double(pkg.discountedRate) / 100.0)
    }
    
    
    private struct RoundedCornerShape: Shape {
        var radius: CGFloat
        var corners: UIRectCorner

        func path(in rect: CGRect) -> Path {
            let path = UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
            return Path(path.cgPath)
        }
    }

    private struct MileagePackageRow: View {
        let title: String
        let subtitle: String
        let trailingText: String?
        let isSelected: Bool
        let position: MileageRowPosition
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(spacing: 16) {
                    // Selection indicator
                    ZStack {
                        Circle()
                            .strokeBorder(lineWidth: 2)
                            .frame(width: 24, height: 24)
                        if isSelected {
                            Circle()
                                .frame(width: 14, height: 14)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(Color("TextBlackPrimary"))
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(Color("FootNote"))
                    }
                    .padding(.leading, 4)

                    Spacer()

                    if let trailing = trailingText {
                        Text(trailing)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("TextBlackPrimary"))
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(backgroundShape)
            }
            .buttonStyle(.plain)
        }

        private var backgroundShape: some View {
            let radius: CGFloat = 18
            let corners: UIRectCorner = {
                switch position {
                case .single:
                    return [.topLeft, .topRight, .bottomLeft, .bottomRight]
                case .first:
                    return [.topLeft, .topRight]
                case .middle:
                    return []
                case .last:
                    return [.bottomLeft, .bottomRight]
                }
            }()

            return RoundedCornerShape(radius: radius, corners: corners)
                .stroke(
                    isSelected ? Color("TextBlackPrimary") : Color("FootNote").opacity(0.3),
                    lineWidth: isSelected ? 2 : 1
                )
        }
    }
    
    @ViewBuilder
    private func UnavailableVehicle() -> some View {
        EmptyView()
    }
    
    @ApiCallActor
    func loadMilagePackageAsync () async -> ApiTaskResponse {
        let request = veygoCurlRequest(
            url: "/api/v1/vehicle/get-mileage-packages",
            method: .get
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let body = ErrorResponse.WRONG_PROTOCOL
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
                return .doNothing
            }
            guard httpResponse.value(forHTTPHeaderField: "Content-Type") == "application/json" else {
                let body = ErrorResponse.E_DEFAULT
                await MainActor.run {
                    alertTitle = body.title
                    alertMessage = body.message
                    showAlert = true
                }
                return .doNothing
            }
            
            switch httpResponse.statusCode {
            case 200:
                nonisolated struct RequestSuccessBody: Decodable {
                    let mileagePackages: [MileagePackage]
                }
                guard let decodedBody = try? VeygoJsonStandard.shared.decoder.decode(RequestSuccessBody.self, from: data) else {
                    let body = ErrorResponse.E_DEFAULT
                    await MainActor.run {
                        alertTitle = body.title
                        alertMessage = body.message
                        showAlert = true
                    }
                    return .doNothing
                }
                await MainActor.run {
                    mileagePackages = decodedBody.mileagePackages
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
            let body = ErrorResponse.E_DEFAULT
            await MainActor.run {
                alertTitle = body.title
                alertMessage = body.message
                showAlert = true
            }
            return .doNothing
        }
    }
}
