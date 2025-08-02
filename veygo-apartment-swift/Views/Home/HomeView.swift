import SwiftUI
import UIKit
import UserNotifications
import GooglePlacesSwift

enum HomeDestination: Hashable {
    case university
    case apartment
}

struct HomeView: View {
    @EnvironmentObject var session: UserSession
    
    @AppStorage("apns_token") var apns_token: String = ""
    
    @State private var selectedToggle: RentalOption = .university
    @State private var selectedLocation: Apartment.ID? = nil
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)
    @State private var promoCode: String = ""
    @Binding var universities: [Apartment]
    
    @State private var path: [HomeDestination] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                
                VStack(alignment: .leading, spacing: 16) {
                    // Make a Reservation & others
                    Title(text: "Make a Reservation", fontSize: 20, color: Color("TextBlackPrimary"))
                        .padding(.horizontal, 24)
                    SlidingToggleButton(selectedOption: $selectedToggle)
                        .padding(.horizontal, 24)
                    Dropdown(
                        selectedOption: $selectedLocation,
                        labelText: .constant("Rental location"),
                        universityOptions: $universities
                    )
                    .padding(.horizontal, 24)
                    DatePanel(startDate: $startDate, endDate: $endDate, isEditMode: true)
                        .padding(.horizontal, 24)
                    
                    // Promo code + Apply
                    HStack(spacing: 16) {
                        InputWithInlinePrompt(promptText: "Promo code / coupon", userInput: $promoCode)
                            .onChange(of: promoCode) { old, newValue in
                                var result = ""
                                var previousWasDash = false
                                for (_, char) in newValue.enumerated() {
                                    if char.isLetter || char.isNumber {
                                        result.append(char)
                                        previousWasDash = false
                                    } else if char == "-" && !previousWasDash && !result.isEmpty {
                                        result.append(char)
                                        previousWasDash = true
                                    }
                                    // skip if it's a dash and previousWasDash is true, or if would be the first character
                                }
                                let finalResult = result.uppercased()
                                if promoCode != finalResult {
                                    promoCode = finalResult
                                }
                            }
                        
                        SecondaryButtonLg(text: "Apply") {
                            if !promoCode.isEmpty {
                                print("Apply tapped with promo code: \(promoCode)")
                            } else {
                                
                            }
                        }
                        .frame(width: 92)
                    }
                    .padding(.horizontal, 24)
                    
                    PrimaryButtonLg(text: "Vehicle Look Up") {
                        path.append(.university)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 120)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                // 顶部图片 + 文字
                ZStack(alignment: .bottomLeading) {
                    Image("HomePageImage")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 220)
                        .clipped()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Title(text: "Good Morning,", fontSize: 24, color: Color.white)
                        Title(text: "\(session.user?.name ?? "Veygo Renter")", fontSize: 24, color: Color.white)
                        Title(text: "Diamond Member", fontSize: 13, color: Color.white)
                    }
                    .padding(.leading, 24)
                    .padding(.bottom, 10)
                }
                .padding(.bottom, 16)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .ignoresSafeArea()
            .navigationDestination(for: HomeDestination.self) { dest in
                switch dest {
                case .apartment: Text("Apartment")
                case .university: FindCarView(path: $path, startDate: $startDate, endDate: $endDate)
                }
            }
            .task {
                await fetchUniversities()
            }
        }
        .refreshable {
            await fetchUniversities()
        }
        .scrollContentBackground(.hidden)
    }
    func fetchUniversities() async {
        let request = veygoCurlRequest(
            url: "/api/v1/apartment/get-universities",
            method: "GET"
        )
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try VeygoJsonStandard.shared.decoder.decode([String: [Apartment]].self, from: data)
            if let unis = decoded["universities"] {
                DispatchQueue.main.async {
                    self.universities = unis
                    self.selectedLocation = unis.first?.id
                }
            }
        } catch {
            print("Failed to fetch universities: \(error)")
        }
    }
}
