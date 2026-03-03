//
//  Plans.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/18/25.
//
import SwiftUI

public struct TripView: View {
    @State private var upcomingReservations: [Agreement] = []
    @Binding var selectedTab: RootDestination
    public var body: some View {
        NavigationStack {
            List {
                if upcomingReservations.isEmpty {
                    VStack (alignment: .center, spacing: 16) {
                        Text("Want to start a new reservation?")
                            .foregroundStyle(Color.textBlackSecondary)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        PrimaryButton(text: "Make a reservation") {
                            selectedTab = .home
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.footNote.opacity(0.5), lineWidth: 1)
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.mainBG)
                }
            }
            .frame(maxWidth: .infinity)
            .listStyle(.plain)
            .scrollIndicators(.hidden)
            .background(Color.mainBG, ignoresSafeAreaEdges: .all)
            .navigationTitle(Text("Trips"))
        }
    }
}
