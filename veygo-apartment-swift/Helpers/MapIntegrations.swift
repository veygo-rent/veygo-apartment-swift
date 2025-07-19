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
            placeProperties: [.displayName, .editorialSummary, .rating, .types, .photos, .placeID],
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

public func fetchPhotos(from photos: [Photo]?) async -> [UIImage] {
    let placesClient = await PlacesClient.shared
    var images: [UIImage] = []
    if let photos = photos {
        var i = 0
        for photo in photos {
            if i == 1 {
                break
            }
            let fetchPhotoRequest = FetchPhotoRequest(photo: photo, maxSize: CGSizeMake(4800, 4800))
            switch await placesClient.fetchPhoto(with: fetchPhotoRequest) {
            case .success(let uiImage):
                // Handle image.
                images.append(uiImage)
            case .failure(let placesError):
                // Handle error
                print(placesError)
            }
            i += 1
        }
    }
    return images
}
