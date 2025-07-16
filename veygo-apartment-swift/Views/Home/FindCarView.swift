//
//  FindCarView.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/1/25.
//

import SwiftUI
import MapKit

struct FindCarView: View {
    @Binding var path: [HomeDestination]
    
    @Binding var startDate: Date
    @Binding var endDate: Date
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
                Car(
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
                ),
                Car(
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
                Car(
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
        ZStack (alignment: .bottom) {
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
            .ignoresSafeArea(.container, edges: [.bottom, .top])
            .simultaneousGesture(
                TapGesture().onEnded {
                    selectedLocation = nil
                }
            )

            if let selected = selectedLocation {
                CarsChoiceView(cars: selected.cars)
                    .frame(height: 300)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: selectedLocation)
            }
        }
        .navigationTitle("Find Your Car")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(
            .thinMaterial,
            for: .navigationBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbar(content: {
            if #unavailable(iOS 26) {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        path.removeLast()
                    }) {
                        BackButton()
                    }
                }
            }
        })
        .modifier(BackButtonHiddenModifier())
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var start = Date()
        @State var end = Date().addingTimeInterval(3600)
        @State private var path: [HomeDestination] = []

        var body: some View {
            NavigationStack {
                FindCarView(path: $path, startDate: $start, endDate: $end)
            }
        }
    }

    return PreviewWrapper()
}
