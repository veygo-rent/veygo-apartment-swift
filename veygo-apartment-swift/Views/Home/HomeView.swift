import SwiftUI
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
    
    @State private var thingsToDo: [String] = []
    
    @available(iOS 26.0, macOS 26.0, *)
    @Generable
    struct TripPlan {
        @Guide(description: "Things to do list. Please tell renter what they can do at the loaction. (e.g., museums, restaurants, parks)")
        @Guide(.count(3))
        let thingsToDo: [String]
    }
    
    @available(iOS 26.0, macOS 26.0, *)
    @Observable
    @MainActor
    final class TripPlanner {
        private var nearbyAttractions: [Place] = []
        private(set) var tripPlan: TripPlan?
        private let session: LanguageModelSession
        
        let school: Apartment
        
        init(school: Apartment) {
            self.school = school
            self.session = LanguageModelSession()
        }
        
        func suggectPlaces(startDate: Date, endDate: Date) async throws {
            let timeDetla = endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970
            let suggestedRadius = (5.0 + (timeDetla - 3600.0) / 3600.0 / 3.5 * 6.0) * 1609.0
            
            self.nearbyAttractions = await findTouristAttractions(near: school.address, radius: suggestedRadius > 50000 ? 50000 : suggestedRadius)
            
            if !nearbyAttractions.isEmpty {
                let attractionsList = nearbyAttractions.map { item -> String in
                    let name = item.displayName ?? "Unknown"
                    let summary = item.editorialSummary ?? "Unknown"
                    return "\(name) – Details: \(summary)"
                }.joined(separator: "\n")
                
                let promptInstructions =
                """
                \nYou are a travel assistant helping a renter plan activities with their rental car. 

                - Pickup location: \(school.name), address: \(school.address).
                - Pickup time (UTC): \(startDate).
                - Return time (UTC): \(endDate).
                  Please convert these times to the local timezone when considering opening hours or events.

                Instructions:
                • Suggest a list of enjoyable places or activities suitable for the time window provided.
                • Factor in opening hours, local time zone, traffic, and the renter's pickup/return location.
                • The rental car has unlimited mileage: feel free to suggest nearby and, if time permits, farther destinations (about 1 mile per minute of intercity travel).
                • For longer rental periods, try to include some out-of-state/province attractions if feasible.
                • Focus on local attractions, dining options, special events, or scenic drives.
                • For each suggestion, include the city and state/province and a brief description.
                • Only suggest content that is safe, neutral, family-friendly, and unrelated to politics, religion, or violence.
                """
                
                let prompt = "\(promptInstructions)\n\nHere are some real nearby tourist attractions you may want to consider including in your suggestions:\n\n\(attractionsList)\n\nNever directly mention the category of the attraction.\nGenerate a list of places the renter can go.\n"
                
                print(prompt)
                let response = try await session.respond(generating: TripPlan.self) {
                    prompt
                }
                self.tripPlan = response.content
            } else {
                let response = try await session.respond(generating: TripPlan.self) {
                    "Generate a list of places the renter can go."
                }
                self.tripPlan = response.content
            }
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
                            }
                        }
                        .frame(width: 92)
                    }
                    
                    PrimaryButtonLg(text: "Vehicle Look Up") {
                        path.append(.university)
                    }
                    if !thingsToDo.isEmpty {
                        Title(text: "Things To Do", fontSize: 20, color: Color("TextBlackPrimary"))
                        ForEach(thingsToDo, id: \.self) { thingToDo in
                            Title(text: thingToDo, fontSize: 16, color: Color("TextBlackSecondary"))
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
            .onChange(of: selectedLocation) { oldValue, newValue in
                thingsToDo = []
                guard let selectedId = newValue,
                      let school = universities.getItemBy(id: selectedId) else { return }
                if #available(iOS 26, *) {
                    let planner = TripPlanner(school: school)
                    Task {
                        do {
                            try await planner.suggectPlaces(startDate: startDate, endDate: endDate)
                            if let things = planner.tripPlan?.thingsToDo {
                                thingsToDo = things
                            }
                        } catch {
                            print("Error suggesting places: \(error)")
                        }
                    }
                }
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

#Preview {
    HomeView()
        .environmentObject(UserSession())
}
