import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: UserSession
    @AppStorage("token") var token: String = ""
    @AppStorage("user_id") var userId: Int = 0
    
    @State private var userName: String = "JUSTIN"
    @State private var selectedToggle: RentalOption = .university
    @State private var selectedLocation = "Purdue University"
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)
    @State private var promoCode: String = ""
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ScrollView {
                // 顶部图片 + 文字
                ZStack(alignment: .bottomLeading) {
                    Image("HomePageImage")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 150)
                        .clipped()

                    VStack(alignment: .leading, spacing: 4) {
                        Title(text: "Good Morning,", fontSize: 24, color: Color.white)
                        Title(text: "\(userName)", fontSize: 24, color: Color.white)
                        Title(text: "Diamond Member", fontSize: 13, color: Color.white)
                    }
                    .padding(.leading, 24)
                    .padding(.bottom, 10)
                }
                VStack (alignment: .leading, spacing: 16) {
                    
                    // Upcoming Trip
                    Title(text: "Upcoming Trip", fontSize: 20, color: Color("TextBlackPrimary"))
                    PanelView(
                        reservationNumber: "PU28367359",
                        dateTime: "Jun 17 at 12:00 PM",
                        location: "Purdue University Main Campus",
                        locationNote: "(Exact location will be provided 30 minutes\nbefore rental starts)",
                        modifyAction: { print("Modify tapped") },
                        cancelAction: { print("Cancel tapped") }
                    )
                    
                    // Make a Reservation & others
                    Title(text: "Make a Reservation", fontSize: 20, color: Color("TextBlackPrimary"))
                    Picker("Rental Option", selection: $selectedToggle) {
                        Text("University").tag(RentalOption.university)
                        Text("Apartment").tag(RentalOption.apartment)
                    }
                    .pickerStyle(.segmented)
                    SlidingToggleButton(selectedOption: $selectedToggle)
                    Dropdown(selectedOption: $selectedLocation, labelText: .constant("Rental location"))
                    DatePanel(startDate: $startDate, endDate: $endDate)
                    // Promo code + Apply
                    HStack (spacing: 16) {
                        InputWithInlinePrompt(promptText: "Promo code / coupon", userInput: $promoCode)
                        
                        LargerSecondaryButtonLg(text: "Apply") {
                            print("Apply tapped with promo code: \(promoCode)")
                        }
                        .frame(width: 92)
                    }
                    // 底部按钮
                    LargerPrimaryButtonLg(text: "Vehicle Look Up", action: {
                        print("Vehicle Look Up tapped")
                    })
                    ShortTextLink(text: "Log out...") {
                        let request = veygoCurlRequest(url: "/api/v1/user/remove-token", method: "GET", headers: ["auth": "\(token)$\(userId)"])
                        URLSession.shared.dataTask(with: request) { data, response, error in
                            guard let httpResponse = response as? HTTPURLResponse else {
                                print("Invalid server response.")
                                return
                            }
                            if httpResponse.statusCode == 200 {
                                token = ""
                                userId = 0
                                DispatchQueue.main.async {
                                    // Update UserSession
                                    self.session.user = nil
                                }
                                print("🧼 Token cleared")
                            }
                        }.resume()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
            .ignoresSafeArea(.container)
            .background(Color("MainBG"))
            .tabItem {
                Image(systemName: "car.fill")
                Text("Home")
            }
            .tag(0)
            
            // tabs
            Text("Trips Page")
                .tabItem {
                    Image(systemName: "star")
                    Text("Trips")
                }
                .tag(1)
            
            Text("Rewards Page")
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Rewards")
                }
                .tag(2)
            
            Text("Settings Page")
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")// 这些都还没跳转
                }
                .tag(3)
        }
    }
}

#Preview {
    HomeView()
}
