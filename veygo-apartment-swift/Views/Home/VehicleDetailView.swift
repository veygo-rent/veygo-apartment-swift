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
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VehicleCardView(vehicle: vehicleWithBlocksAndLocationInfo.0, apartment: apartment, startDate: startTime, endDate: endTime)
                    .padding(.top, 24)
                if vehicleWithBlocksAndLocationInfo.0.isVehicleAvailable(start: startTime, end: endTime) {
                    AvailableVehicle()
                } else {
                    UnavailableVehicle()
                }
                Text("Your destination is: \(vehicleWithBlocksAndLocationInfo.1.name)")
                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color("MainBG"))
        .toolbar(content: {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    path.removeLast()
                }) {
                    if #unavailable(iOS 26) {
                        BackButton()
                    } else {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        })
        .navigationBarBackButtonHidden(true)
    }
    
    @ViewBuilder
    private func AvailableVehicle() -> some View {
        GroupBox("Protection options") {
            VStack(alignment: .leading, spacing: 12) {
                if let rate = apartment.liabilityProtectionRate {
                    Toggle(isOn: $includeLiability) {
                        HStack {
                            Text("Liability")
                            Spacer()
                            Text("\(formatRate(rate))/hr")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 4)
                        }
                    }
                }
                if let rate = apartment.pcdwProtectionRate {
                    let weightedRate = rate * vehicleWithBlocksAndLocationInfo.0.vehicle.msrpFactor
                    Toggle(isOn: $includePCDW) {
                        HStack {
                            Text("PCDW")
                            Spacer()
                            Text("\(formatRate(weightedRate))/hr")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 4)
                        }
                    }
                }
                if let rate = apartment.pcdwExtProtectionRate {
                    let weightedRate = rate * vehicleWithBlocksAndLocationInfo.0.vehicle.msrpFactor
                    Toggle(isOn: $includePCDWExt) {
                        HStack {
                            Text("PCDW Extension")
                            Spacer()
                            Text("\(formatRate(weightedRate))/hr")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 4)
                        }
                    }
                }
                if let rate = apartment.rsaProtectionRate {
                    Toggle(isOn: $includeRSA) {
                        HStack {
                            Text("RSA (Roadside Assistance)")
                            Spacer()
                            Text("\(formatRate(rate))/hr")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 4)
                        }
                    }
                }
                if let rate = apartment.paiProtectionRate {
                    Toggle(isOn: $includePAI) {
                        HStack {
                            Text("PAI (Personal Accident)")
                            Spacer()
                            Text("\(formatRate(rate))/hr")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 4)
                        }
                    }
                }
                if apartment.liabilityProtectionRate == nil
                    && apartment.pcdwProtectionRate == nil
                    && apartment.pcdwExtProtectionRate == nil
                    && apartment.rsaProtectionRate == nil
                    && apartment.paiProtectionRate == nil {
                    Text("No protection options offered for this location.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .cornerRadius(18)
        .backgroundStyle(Color("CardBG"))
    }

    private func formatRate(_ rate: Double) -> String {
        let number = NSNumber(value: rate)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: number) ?? "$\(String(format: "%.2f", rate))"
    }
    
    @ViewBuilder
    private func UnavailableVehicle() -> some View {
        EmptyView()
    }
}
