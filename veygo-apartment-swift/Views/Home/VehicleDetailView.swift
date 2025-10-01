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
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}
