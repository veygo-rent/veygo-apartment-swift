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
    @State private var offset: CGFloat = 0
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
    private let headerHeight: CGFloat = 300
    var body: some View {
        ZStack (alignment: .top) {
            ScrollView {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: headerHeight)

                VStack(alignment: .leading, spacing: 20) {
                    if vehicleWithBlocksAndLocationInfo.0.isVehicleAvailable(start: startTime, end: endTime) {
                        Text("\(offset)")
                        AvailableVehicle()
                    } else {
                        UnavailableVehicle()
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onScrollGeometryChange(for: CGFloat.self, of: { geo in
                return 0 - geo.contentOffset.y - geo.contentInsets.top
            }, action: { new, old in
                offset = new
            })
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
            .frame(height: headerHeight + max(0, offset))
            .clipped()
            .transformEffect(.init(translationX: 0, y: min(0, offset)))
        }
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
