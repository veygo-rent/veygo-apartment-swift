//
//  FindCarView.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/1/25.
//

import SwiftUI
import MapKit

struct CarLocation: Identifiable, Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let cars: [CarModel]

    static func == (lhs: CarLocation, rhs: CarLocation) -> Bool {
        return lhs.id == rhs.id
    }
}

struct FindCarView: View {
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
            // 顶部固定时间 banner
            TimeBanner(startDate: startDate, endDate: endDate) {
                print("Change tapped")
            }
            .frame(height: 100)
            .ignoresSafeArea(.container, edges: .top)

            // 地图 + 底部车辆卡片区域
            ZStack(alignment: .bottom) {
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

                if let selected = selectedLocation {
                    CarsChoiceView(cars: selected.cars)
                        .frame(height: 300)
                        .transition(.move(edge: .bottom))
                        .animation(.easeInOut, value: selectedLocation)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var start = Date()
        @State var end = Date().addingTimeInterval(3600)

        var body: some View {
            NavigationStack {
                FindCarView(startDate: $start, endDate: $end)
            }
        }
    }

    return PreviewWrapper()
}
