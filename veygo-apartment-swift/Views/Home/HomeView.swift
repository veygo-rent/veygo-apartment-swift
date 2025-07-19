import SwiftUI
import UIKit
import UserNotifications
import FoundationModels
import GooglePlacesSwift

enum HomeDestination: Hashable {
    case university
    case apartment
}

struct HomeView: View {
    @EnvironmentObject var session: UserSession
    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0
    @AppStorage("apns_token") var apns_token: String = ""
    
    @State private var selectedToggle: RentalOption = .university
    @State private var selectedLocation: Apartment.ID? = nil
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)
    @State private var promoCode: String = ""
    @State private var universities: [Apartment] = []
    
    @State private var path: [HomeDestination] = []
    
    @State private var thingsToDo: [PlaceWithDescription]? = []
    
    struct PlaceOption {
        let place: Place
    }
    
    struct PlaceWithDescription: Identifiable {
        let id = UUID()
        
        let place: Place
        let photos: [UIImage]
        let description: String
    }
    
    @available(iOS 26.0, macOS 26.0, *)
    @Observable
    @MainActor
    final class TripPlanner {
        /// TripPlan represents a planned trip with a selected place and description.
        /// The guide for valid places is provided statically via placesGuide,
        /// which must be set prior to generating a TripPlan instance.
        @Generable
        struct PlaceDescriptions {
            @Guide(.count(5))
            let places: [PlaceDescription]
        }
        
        @Generable
        struct PlaceDescription {
            /// Static list of place IDs used as the guide for the place selection.
            /// This must be set before generating a TripPlan.
            static var placesIds: [String] = []
            
            @Guide(.anyOf(placesIds))
            @Guide(description: "Records the Place ID of a place")
            let placeID: String
            @Guide(description: "A short description of the Place")
            let description: String
        }
        
        var nearbyAttractions: [PlaceOption] = []
        private(set) var tripPlan: PlaceDescriptions?
        private let session: LanguageModelSession
        
        let school: Apartment
        let startDate: Date
        let endDate: Date
        
        init(school: Apartment, startDate: Date, endDate: Date) {
            self.school = school
            self.startDate = startDate
            self.endDate = endDate
            
            // Refined prompt for trip assistant.
            self.session = LanguageModelSession{
                """
                You are a travel assistant helping a renter make the most out of their rental car period by suggesting enjoyable places and activities.
                
                Pickup Details:
                - Location: \(school.name), \(school.address)
                - Pickup Time (UTC): \(startDate)
                - Return Time (UTC): \(endDate)
                - Please convert these times to the local timezone when considering opening hours or events.
                
                Instructions:
                1. Suggest a short, ranked list of places or activities fitting the available rental period and their locations.
                2. For each suggestion:
                    - Provide the name, city, and state/province.
                    - Add a concise, enticing description (avoid naming the type of attraction directly).
                    - Mention any unique features, seasonal events, or local tips if relevant.
                3. Consider:
                    - Opening hours and travel time.
                    - The renter's pickup and return location.
                    - Both nearby and farther destinations (given unlimited mileage).
                    - For longer rentals, suggest some out-of-state/province attractions if practical.
                    - Focus on student-friendly, neutral, and safe content.
                """
            }
        }
        
        func loadNearbyAttractions() async {
            PlaceDescription.placesIds = []
            let timeDetla = endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970
            let suggestedRadius = (5.0 + (timeDetla - 3600.0) / 3600.0 / 3.5 * 6.0) * 1609.0
            
            let places = await findTouristAttractions(near: school.address, radius: suggestedRadius > 50000 ? 50000 : suggestedRadius)
            for place in places {
                PlaceDescription.placesIds.append(place.placeID ?? "")
                nearbyAttractions.append(.init(place: place))
            }
        }
        
        func suggectPlaces() async throws -> [PlaceWithDescription] {
            var places: [PlaceWithDescription] = []
            if !nearbyAttractions.isEmpty {
                let attractionsListPrompt: String = nearbyAttractions.map { item -> String in
                    let place = item.place
                    let name = place.displayName ?? "Unknown"
                    let summary = place.editorialSummary ?? "Unknown"
                    let placeID: String = place.placeID!
                    let ratingDescription: String = {
                        if let rating = place.rating {
                            return " with a rating of \(rating) out of 5"
                        } else {
                            return ""
                        }
                    }()
                    return "\(name) (Place ID: \(placeID)) – Details: \(summary)\(ratingDescription)"
                }.joined(separator: "\n")
                
                // Refined prompt for trip assistant.
                let prompt = """
                Here are some real nearby tourist attractions you may want to consider including in your suggestions:\n\n\(attractionsListPrompt)\n\n
                
                Please do not mention the type/category of the attraction directly. Generate a list of places the renter can go that match the instructions above.
                """
                
                let response = try await session.respond(generating: PlaceDescriptions.self) {
                    prompt
                }
                self.tripPlan = response.content
                if let tripPlan = tripPlan {
                    for place in tripPlan.places {
                        if let placeData = nearbyAttractions.getPlaceBy(id: place.placeID) {
                            let images = await fetchPhotos(from: placeData.photos)
                            places.append(.init(place: placeData, photos: images, description: place.description))
                        }
                    }
                }
            }
            return places
        }
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                
                VStack(alignment: .leading, spacing: 16) {
                    // Make a Reservation & others
                    Title(text: "Make a Reservation", fontSize: 20, color: Color("TextBlackPrimary"))
                    SlidingToggleButton(selectedOption: $selectedToggle)
                    Dropdown(
                        selectedOption: $selectedLocation,
                        labelText: .constant("Rental location"),
                        universityOptions: $universities
                    )
                    DatePanel(startDate: $startDate, endDate: $endDate, isEditMode: true)
                    
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
                                thingsToDo = []
                                if #available(iOS 26, *) {
                                    guard let selectedId = selectedLocation,
                                          let school = universities.getItemBy(id: selectedId) else { return }
                                    let planner = TripPlanner(school: school, startDate: startDate, endDate: endDate)
                                    Task {
                                        do {
                                            await planner.loadNearbyAttractions()
                                            thingsToDo = try await planner.suggectPlaces()
                                        } catch {
                                            print("Error suggesting places: \(error)")
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: 92)
                    }
                    
                    PrimaryButtonLg(text: "Vehicle Look Up") {
                        path.append(.university)
                    }
                    
                    if let thingsToDo = thingsToDo {
                        if !thingsToDo.isEmpty {
                            Text("Things to do")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(thingsToDo) { thing in
                                        VStack(alignment: .leading, spacing: 8) {
                                            Image(uiImage: thing.photos.first!)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 120, height: 120)
                                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                                .clipped()
                                            Text(thing.place.displayName ?? "Unknown")
                                                .font(.headline)
                                            Text(thing.description)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(3)
                                        }
                                        .frame(width: 160)
                                        .padding(10)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                    }
                                }
                                .padding(.vertical, 2)
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
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

extension Array where Element == HomeView.PlaceOption {
    func getPlaceBy(id: String) -> Place? {
        return self.first { $0.place.placeID ?? "" == id }?.place
    }
}

#Preview {
    HomeView()
        .environmentObject(UserSession())
}
