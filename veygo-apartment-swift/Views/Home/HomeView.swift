import SwiftUI
import UserNotifications
import FoundationModels

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
        @Guide(description: "Things to do list")
        @Guide(.count(3))
        let thingsToDo: [String]
    }
    
    @available(iOS 26.0, macOS 26.0, *)
    @Observable
    @MainActor
    final class TripPlanner {
        private(set) var tripPlan: TripPlan?
        private let session: LanguageModelSession
        
        let school: Apartment
        
        init(school: Apartment, startDate: Date, endDate: Date) {
            self.school = school
            self.session = LanguageModelSession {
                "Your job is to help the renter figuring our what he or she can do with our rental car. "
                "Here's the address of the school named \(school.name): \(school.address). "
                "The renter is picking up our car at the time of \(startDate) and returning it at \(endDate). "
                "The pick up and drop off locations are basically at the school. "
                "Please give the renter a list of places that they can go based on the time they have, places' opening hours, school's timezone, traffic conditions and any other constraints."
                "Our rental car is unlimited mileage, so if time permits, you can suggest places that are far from the school. And for yourb reference, intercity travel is roughly one mile per minute (eg. West Lafayette Indiana to Chicago is 2 hours). "
            }
        }
        
        func suggectPlaces() async throws {
            let response = try await session.respond(generating: TripPlan.self) {
                "Generate a list of places the renter can go."
            }
            self.tripPlan = response.content
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
                    print("\nStart Time: \(startDate). End Time: \(endDate).")
                    let planner = TripPlanner(school: school, startDate: startDate, endDate: endDate)
                    Task {
                        do {
                            try await planner.suggectPlaces()
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
