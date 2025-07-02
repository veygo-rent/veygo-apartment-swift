//
//  FindCarView.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/1/25.
//
import SwiftUI
import MapKit

struct CarLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let cars: [CarModel]
}

struct FindCarView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.4237, longitude: -86.9212),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    @State private var selectedLocation: CarLocation? = nil

    let locations: [CarLocation] = [
        CarLocation(
            coordinate: CLLocationCoordinate2D(latitude: 40.4225, longitude: -86.9215),
            title: "Hillenbrand Hall",
            cars: [
                CarModel(
                    location: "Purdue: Hillenbrand Hall",
                    timeText: "16 min",
                    name: "Kia Forte",
                    price: "$9.99/hr - $69.99/day",
                    features: [
                        "Android Auto / Apple CarPlay",
                        "Automatic Transmission",
                        "Collision Detection"
                    ],
                    imageName: "kia_forte",
                    iconName: "figure.walk"
                )
            ]
        ),
        CarLocation(
            coordinate: CLLocationCoordinate2D(latitude: 40.4242, longitude: -86.9208),
            title: "Elliott Hall",
            cars: [
                CarModel(
                    location: "Purdue: Elliott Hall",
                    timeText: "12 min",
                    name: "Toyota Corolla",
                    price: "$10.99/hr - $74.99/day",
                    features: [
                        "Bluetooth Audio",
                        "Backup Camera",
                        "Lane Assist"
                    ],
                    imageName: "toyota_corolla",
                    iconName: "figure.walk"
                )
            ]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            Map(coordinateRegion: $region, annotationItems: locations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    Button(action: {
                        withAnimation {
                            region.center = location.coordinate
                            region.span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                            selectedLocation = location
                        }
                    }) {
                        Image("Pin")
                            .resizable()
                            .frame(width: 48, height: 48)
                    }
                }
            }
            .frame(height: 350)

            if let selected = selectedLocation {
                CarsChoiceView(cars: selected.cars)
                    .frame(height: 260)
            } else {
                Text("Select a location on the map to see available cars.")
                    .frame(maxWidth: .infinity, maxHeight: 260)
                    .background(Color("GrayPrimaryBG"))
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    FindCarView()
}

