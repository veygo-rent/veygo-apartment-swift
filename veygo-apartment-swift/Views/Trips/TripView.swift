//
//  Plans.swift
//  veygo-apartment-swift
//
//  Created by 魔法玛丽大炮 on 5/18/25.
//
import SwiftUI

struct TripView: View {
    @State private var upcomingReservations: [Agreement] = []
    @Binding var selectedTab: RootDestination
    public var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    HistoryView()
                } label: {
                    HStack {
                        Text("History and Receipts")
                            .foregroundStyle(Color.accentColor)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding()
                    .background(Color.cardBG)
                    .cornerRadius(10)
                }
                .navigationLinkIndicatorVisibility(.hidden)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.mainBG)
                
                if upcomingReservations.isEmpty {
                    VStack (alignment: .center, spacing: 16) {
                        Text("Want to start a new reservation?")
                            .foregroundStyle(Color.textBlackPrimary)
                            .font(.title2)
                            .fontWeight(.bold)
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
