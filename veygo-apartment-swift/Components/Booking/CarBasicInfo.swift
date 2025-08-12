//
//  CarBasicInfo.swift
//  veygo-apartment-swift
//
//  Created by sardine on 8/2/25.
//

import SwiftUI

struct CarBasicInfo: View {
    let vehicle: PublishVehicle

    @State private var imageData: Data? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(vehicle.name)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(Color("TextBlackPrimary"))

                Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("FootNote"))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Text("License Plate: \(vehicle.licenseNumber)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("FootNote"))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.leading, 4)

            Spacer()

            vehicleImage()
                .frame(width: 199, height: 200)
                .cornerRadius(8)
        }
        .task {
            await loadVehicleImage()
        }
    }

    @ViewBuilder
    private func vehicleImage() -> some View {
        if let data = imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage) //binary 转 PNG
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "car.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(Color("FootNote"))
        }
    }

    private func loadVehicleImage() async {
            let testURLString = "https://e-n-cars.ru/wp-content/uploads/2024/06/tesla-model-3.webp"

            guard let url = URL(string: testURLString) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                await MainActor.run {
                    self.imageData = data //binary
                }
            } catch {
                print("Image download failed: \(error.localizedDescription)")
            }
        }
}
