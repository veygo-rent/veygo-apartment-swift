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
    @State private var universities: [Apartment] = []
    
    @State private var path: [HomeDestination] = []
    
    struct PlaceOption {
        let place: Place
    }
    
    struct PlaceWithDescription: Identifiable {
        let id = UUID()
        
        let place: Place
        let description: String
    }
    
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
    
    struct ThingToDoView: View {
        var thing: PlaceWithDescription?
        @State private var img: UIImage? = nil
        var body: some View {
            Group {
                if let thing = thing {
                    VStack (alignment: .leading) {
                        Text(thing.place.displayName ?? "Unknown")
                            .font(.title3)
                            .foregroundStyle(Color("TextBlackPrimary"))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(width: 350, alignment: .leading)
                            .padding(.bottom)
                        HStack (alignment: .top, spacing: 20) {
                            VStack (alignment: .leading) {
                                if let rating = thing.place.rating {
                                    Text("Rating: \(rating, format: .number.precision(.fractionLength(1)))/5.0")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Text(thing.description)
                                    .font(.body)
                                    .frame(width: 200, alignment: .leading)
                                    .lineLimit(5)
                            }
                            if let img = img {
                                Image(uiImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 140, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .clipped()
                            } else {
                                Image("VeygoLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 140, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .clipped()
                                    .redacted(reason: .placeholder)
                            }
                        }
                    }
                    .onAppear {
                        if img == nil {
                            Task {
                                img = await fetchPhoto(from: thing.place.photos)
                            }
                        }
                    }
                } else {
                    VStack (alignment: .leading) {
                        Text("Unknown")
                            .progressViewStyle(.linear)
                            .font(.title3)
                            .foregroundStyle(Color("TextBlackPrimary"))
                            .redacted(reason: .placeholder)
                            .padding(.bottom)
                        HStack (alignment: .top, spacing: 20) {
                            VStack (alignment: .leading) {
                                Text("Rating: Unknown")
                                    .progressViewStyle(.linear)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .redacted(reason: .placeholder)
                                Text("Apple's mission is \"to bring the best user experience to its customers through its innovative hardware, software, and services.\"")
                                    .progressViewStyle(.linear)
                                    .font(.body)
                                    .frame(width: 200, alignment: .leading)
                                    .lineLimit(5)
                                    .redacted(reason: .placeholder)
                            }
                            Image("VeygoLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 140, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .clipped()
                                .redacted(reason: .placeholder)
                        }
                    }
                }
            }
            .frame(height: 180)
            .padding(16)
            .background(Color("CardBG"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

extension Array where Element == HomeView.PlaceOption {
    func getPlaceBy(id: String) -> Place? {
        return self.first { $0.place.placeID ?? "" == id }?.place
    }
}

#Preview {
    HomeView()
        .environmentObject(UserSession())
}
