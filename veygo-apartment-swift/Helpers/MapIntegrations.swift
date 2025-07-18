//
//  MapIntegration.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 7/17/25.
//

import Foundation
import MapKit
import CoreLocation

public func findTouristAttractions(near address: String) async -> [MKMapItem] {
    let geocoder = CLGeocoder()
    do {
        let placemarks = try await geocoder.geocodeAddressString(address)
        guard let location = placemarks.first?.location else { return [] }
        let coordinate = location.coordinate
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "tourist attraction"
        request.region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems
    } catch {
        return []
    }
}
