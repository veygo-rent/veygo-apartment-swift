//
//  MapIntegration.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 7/17/25.
//

import Foundation
import GooglePlacesSwift
import CoreLocation

public func findTouristAttractions(near address: String, radius: Double) async -> [Place] {
    let geocoder = CLGeocoder()
    let placesClient = await PlacesClient.shared
    do {
        let placemarks = try await geocoder.geocodeAddressString(address)
        guard let coordinate = placemarks.first?.location?.coordinate else {
            return []
        }
        let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let restriction = CircularCoordinateRegion(center: center, radius: radius)
        let request = SearchNearbyRequest(
            locationRestriction: restriction,
            placeProperties: [.displayName, .editorialSummary, .addressComponents, .rating],
            includedTypes: [.touristAttraction]
        )
        switch await placesClient.searchNearby(with: request) {
        case .success(let places):
            return places
        case .failure(_):
            return []
        }
    } catch {
        return []
    }
}
