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
        let description: String
    }
    
    @available(iOS 26.0, macOS 26.0, *)
    final class TripPlanner {
        
        @Generable
        struct PlaceDescriptions {
            @Guide(.count(10))
            let places: [PlaceDescription]
        }
        
        @Generable
        struct PlaceDescription {
            
            nonisolated(unsafe) static var placesIds: [String] = []
            
            @Guide(.anyOf(placesIds))
            @Guide(description: "Records the Place ID of a place")
            let placeID: String
            @Guide(description: "A short description of the Place, explicitly mention what city the place is in")
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
                4. Include a mix of well-known and lesser-known (not so famous) local places, such as hidden gems or local favorites that may not appear in typical tourist guides. 
                """
            }
        }
        
        func loadNearbyAttractions() async {
            await MainActor.run {
                PlaceDescription.placesIds = []
            }
            let timeDetla = endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970
            let suggestedRadius = (5.0 + (timeDetla - 3600.0) / 3600.0 / 3.5 * 6.0) * 1609.0
            
            let places = await findTouristAttractions(near: school.address, radius: suggestedRadius > 50000 ? 50000 : suggestedRadius)
            for place in places {
                await MainActor.run {
                    PlaceDescription.placesIds.append(place.placeID ?? "")
                }
                nearbyAttractions.append(.init(place: place))
            }
        }
        
        func suggectPlaces() async throws -> [PlaceWithDescription] {
            var places: [PlaceWithDescription] = []
            if !nearbyAttractions.isEmpty {
                let forbiddenKeywords = ["Six Flags"]
                var attractionsListPromptArr: [String] = []
                for item in nearbyAttractions {
                    let place = item.place
                    let name = place.displayName ?? "Unknown"
                    let summary = place.editorialSummary ?? "Unknown"
                    let placeID: String = place.placeID!
                    let address = place.addressComponents ?? []
                    let ratingDescription: String = {
                        if let rating = place.rating {
                            return " with a rating of \(rating) out of 5"
                        } else {
                            return ""
                        }
                    }()
                    let location: String = {
                        if address.isEmpty {
                            return ""
                        } else {
                            let locationDesc = address.compactMap { addrComp in
                                if addrComp.types.contains(.political) {
                                    if addrComp.name == "United States" {
                                        return nil
                                    } else {
                                        return addrComp.name
                                    }
                                } else {
                                    return nil
                                }
                            }.joined(separator: ", ")
                            let returnVar = " located in " + locationDesc
                            return returnVar
                        }
                    }()
                    let finalPlacePrompt = "\(name) (Place ID: \(placeID)) – Details: \(summary)\(ratingDescription)\(location)"
                    // Filter forbidden keywords
                    if forbiddenKeywords.contains(where: { finalPlacePrompt.localizedCaseInsensitiveContains($0) }) {
                        await MainActor.run {
                            if let index = PlaceDescription.placesIds.firstIndex(of: placeID) {
                                PlaceDescription.placesIds.remove(at: index)
                            }
                        }
                        continue
                    }
                    attractionsListPromptArr.append(finalPlacePrompt)
                }
                let attractionsListPrompt = attractionsListPromptArr.joined(separator: "\n")
                
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
                            places.append(.init(place: placeData, description: place.description))
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
                        .padding(.horizontal, 24)
                    SlidingToggleButton(selectedOption: $selectedToggle)
                        .padding(.horizontal, 24)
                    Dropdown(
                        selectedOption: $selectedLocation,
                        labelText: .constant("Rental location"),
                        universityOptions: $universities
                    )
                    .padding(.horizontal, 24)
                    .onChange(of: selectedLocation) { oldValue, newValue in
                        if #available(iOS 26, *) {
                            thingsToDo = nil
                            guard let selectedId = selectedLocation,
                                  let school = universities.getItemBy(id: selectedId) else { return }
                            let planner = TripPlanner(school: school, startDate: startDate, endDate: endDate)
                            Task {
                                do {
                                    await planner.loadNearbyAttractions()
                                    thingsToDo = try await planner.suggectPlaces()
                                } catch {
                                    thingsToDo = []
                                    print("Error suggesting places: \(error)")
                                }
                            }
                        }
                    }
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
                    
                    if let thingsToDo = thingsToDo {
                        if !thingsToDo.isEmpty {
                            Title(text: "Things to Do", fontSize: 20, color: Color("TextBlackPrimary"))
                                .padding(.horizontal, 24)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(thingsToDo) { thing in
                                        ThingToDoView(thing: thing)
                                    }
                                }
                                .padding(.vertical, 2)
                                .padding(.horizontal, 24)
                            }
                            .scrollContentBackground(.hidden)
                        }
                    } else {
                        Title(text: "Things to Do", fontSize: 20, color: Color("TextBlackPrimary"))
                            .padding(.horizontal, 24)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ThingToDoView(thing: nil)
                            }
                            .padding(.vertical, 2)
                            .padding(.horizontal, 24)
                        }
                        .scrollContentBackground(.hidden)
                    }
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
