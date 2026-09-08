//
//  VehicleDetailView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 9/7/26.
//

import SwiftUI

struct VehicleDetailView: View {
    @Environment(Router.self) private var router

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    // Carried in from HomeDestination.vehicleDetails — values, not bindings.
    let startTime: Date
    let endTime: Date
    let apartment: Apartment
    let vehicleWithBlocksAndLocationInfo: (VehicleWithBlockedDurations, Location)
    let taxes: [Tax]
    let rateOffer: RateOffer
    let promo: PublishPromo?

    private var vehicle: PublishRenterVehicle { vehicleWithBlocksAndLocationInfo.0.vehicle }

    private var pricingStandard: VeygoPricingStandard {
        VeygoPricingStandard(apartment: apartment, vehicle: vehicle)
    }

    @State private var mileagePackage: MileagePackage?
    @State private var mileagePackages: [MileagePackage] = []

    private enum MileageRowPosition {
        case single, first, middle, last
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
                        Text(vehicle.name)
                            .textCase(.uppercase)
                            .font(.title)
                            .fontWeight(.heavy)
                            .foregroundStyle(Color("TextBlackPrimary"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                            .font(.callout)
                            .foregroundStyle(Color("FootNote"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Grid(alignment: .leading, verticalSpacing: 10) {
                            GridRow {
                                Image(systemName: "person.fill")
                                    .gridColumnAlignment(.center)
                                Text("^[\(vehicle.capacity) Person](inflect: true)")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 4)
                                Image(systemName: "car.top.arrowtriangle.rear.right.fill")
                                    .gridColumnAlignment(.center)
                                Text("^[\(vehicle.doors) Door](inflect: true)")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 4)
                            }
                            GridRow {
                                Image(systemName: "suitcase.fill")
                                Text("^[\(vehicle.smallBags) Small Bag](inflect: true)")
                                    .padding(.leading, 4)
                                Image(systemName: "suitcase.rolling.and.suitcase.fill")
                                Text("^[\(vehicle.largeBags) Large Bag](inflect: true)")
                                    .padding(.leading, 4)
                            }
                            GridRow {
                                Image(systemName: "location.app.fill")
                                Text(vehicle.carplay ? "Apple CarPlay" : "In Car Navigation")
                                    .padding(.leading, 4)
                                Image(systemName: vehicle.laneKeep ? "car.rear.road.lane" : "gauge.open.with.lines.needle.67percent.and.arrowtriangle.and.car")
                                Text(vehicle.laneKeep ? "Lane Keeping" : "Cruise Control")
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
                        availableVehicle
                    } else {
                        unavailableVehicle
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(Color("MainBG"))
        .ignoresSafeArea(.container, edges: .top)
        .task {
            await loadMileagePackages()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Available / unavailable sections

    @ViewBuilder
    private var availableVehicle: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Mileage package")
                .font(.headline)
                .foregroundStyle(Color("TextBlackPrimary"))
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                let hasPackages = !mileagePackages.isEmpty

                MileagePackageRow(
                    title: "10 Miles Free",
                    subtitle: pricingStandard.perMileSubtitle(),
                    trailingText: "Included",
                    isSelected: mileagePackage == nil,
                    position: hasPackages ? .first : .single,
                    action: { mileagePackage = nil }
                )

                ForEach(Array(mileagePackages.enumerated()), id: \.element.id) { index, pkg in
                    let isLast = index == mileagePackages.count - 1
                    MileagePackageRow(
                        title: "\(10 + pkg.miles) Miles",
                        subtitle: pricingStandard.perMileSubtitle(),
                        trailingText: formatRate(pricingStandard.mileagePackagePrice(for: pkg)),
                        isSelected: mileagePackage == pkg,
                        position: isLast ? .last : .middle,
                        action: { mileagePackage = pkg }
                    )
                }
            }

            PrimaryButton(text: "Continue") {
                router.push(HomeDestination.summary(
                    vehicle: vehicle,
                    location: vehicleWithBlocksAndLocationInfo.1,
                    apartment: apartment,
                    rateOffer: rateOffer,
                    mileagePackage: mileagePackage,
                    promo: promo,
                    taxes: taxes,
                    startDate: startTime,
                    endDate: endTime
                ))
            }
            .padding(.top, 6)
        }
        .padding()
    }

    @ViewBuilder
    private var unavailableVehicle: some View {
        EmptyView()
    }

    private func formatRate(_ rate: Decimal) -> String {
        VeygoCurrencyStandard.shared.dollarFormatter.string(from: rate as NSDecimalNumber) ?? "$0.00"
    }

    // MARK: - Mileage packages

    private func loadMileagePackages() async {
        do {
            mileagePackages = try await fetchMileagePackages()
        } catch let error as VeygoError {
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func fetchMileagePackages() async throws -> [MileagePackage] {
        let request = veygoCurlRequest(url: "/api/v1/vehicle/mileage-packages", method: .get)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { throw VeygoError.unknown }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return try VeygoJsonStandard.shared.decoder.decode([MileagePackage].self, from: data)
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

    // MARK: - Mileage row

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
                    ZStack {
                        Circle()
                            .strokeBorder(lineWidth: 2)
                            .frame(width: 24, height: 24)
                        if isSelected {
                            Circle().frame(width: 14, height: 14)
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
            let corners: UIRectCorner = {
                switch position {
                case .single: return [.topLeft, .topRight, .bottomLeft, .bottomRight]
                case .first:  return [.topLeft, .topRight]
                case .middle: return []
                case .last:   return [.bottomLeft, .bottomRight]
                }
            }()
            return RoundedCornerShape(radius: 18, corners: corners)
                .stroke(
                    isSelected ? Color("TextBlackPrimary") : Color("FootNote").opacity(0.3),
                    lineWidth: isSelected ? 2 : 1
                )
        }
    }
}
