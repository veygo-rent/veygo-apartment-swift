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
                            .fontWeight(.bold)
                            .font(.title)
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
                                Text("5 People")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 4)
                                Image(systemName: "car.top.arrowtriangle.rear.right.fill")
                                    .gridColumnAlignment(.center)
                                Text("4 Doors")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 4)
                            }
                            GridRow {
                                Image(systemName: "suitcase.fill")
                                Text("2 Small Bags")
                                    .padding(.leading, 4)
                                Image(systemName: "figure.walk.suitcase.rolling.circle.fill")
                                Text("2 Big Bags")
                                    .padding(.leading, 4)
                            }
                            GridRow {
                                Image(systemName: "location.app.fill")
                                Text("In Car Nav")
                                    .padding(.leading, 4)
                                Image(systemName: "car.rear.road.lane")
                                Text("Lane Keep")
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
        .ignoresSafeArea(.container)
    }
    
    @ViewBuilder
    private func AvailableVehicle() -> some View {
        EmptyView()
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
