//
//  MapIntegration.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 7/17/25.
//

import Foundation
import GooglePlacesSwift
import CoreLocation
import UIKit

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
            placeProperties: [.displayName, .editorialSummary, .rating, .types, .photos, .placeID, .addressComponents],
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

public func fetchPhoto(from photos: [Photo]?) async -> UIImage? {
    let placesClient = await PlacesClient.shared
    guard let photos = photos, !photos.isEmpty else { return nil }
    let randomPhoto = photos.randomElement()!
    let fetchPhotoRequest = FetchPhotoRequest(photo: randomPhoto, maxSize: CGSizeMake(4800, 4800))
    switch await placesClient.fetchPhoto(with: fetchPhotoRequest) {
    case .success(let uiImage):
        return uiImage
    case .failure(let placesError):
        print(placesError)
        return nil
    }
}
