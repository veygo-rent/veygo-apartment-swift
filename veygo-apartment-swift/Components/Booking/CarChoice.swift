//
//  CarChoice.swift
//  veygo-apartment-swift
//
//  Created by sardine on 7/1/25.
//

import SwiftUI

struct CarsChoiceView: View {
    var cars: [Car]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(cars) { car in
                    VStack(alignment: .leading, spacing: 8) {
                        // 顶部地址 + icon + 时间
                        HStack {
                            Text(car.location)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color("TextBlackPrimary"))

                            Spacer()

                            Image(systemName: car.iconName)
                                .resizable()
                                .frame(width: 19, height: 17)

                            Text(car.timeText)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color("TextBlackPrimary"))
                        }
                        .padding(.horizontal, 25)
                        .frame(height: 40)

                        // 白色卡片区域，居中对齐
                        HStack {
                            Spacer()

                            ZStack(alignment: .bottomTrailing) {
                                // 内容
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(car.name)
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(Color("TextBlackPrimary"))

                                            Text(car.price)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(Color("TextBluePrimary"))
                                        }

                                        Spacer()

                                        Image(car.imageName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 95, height: 55)
                                    }

                                    Text("Features:")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color("TextBlackPrimary"))

                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(car.features, id: \.self) { feature in
                                            Text("• \(feature)")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(Color("TextBlackPrimary"))
                                        }
                                    }

                                    Spacer() // 为底部按钮留出空间
                                }
                                .padding(12)

                                // 右下角按钮
                                LargerSecondaryButtonLg(text: "Book") {
                                    print("Book tapped for \(car.name)")
                                }
                                .padding([.bottom, .trailing], 12)
                                .frame(width: 92)
                            }
                            .frame(width: 335, height: 190)
                            .background(Color("CardBG"))

                            Spacer()
                        }
                    }
                    .frame(width: 401, height: 252)
                    .background(Color("MainBG"))
                }
            }
        }
    }
}

#Preview {
    CarsChoiceView(cars: [
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
            location: "Purdue: Hawkins Hall",
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
    ])
}
