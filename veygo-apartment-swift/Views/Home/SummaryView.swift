//
//  SummaryView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 3/9/26.
//

import SwiftUI

struct SummaryView: View {
    
    @Binding var path: [HomeDestination]
    
    let startDate: Date
    let endDate: Date
    
    let vehicle: PublishRenterVehicle
    let apartment: Apartment
    let location: Location
    let promo: PublishPromo?
    let mileagePackage: MileagePackage?
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}
