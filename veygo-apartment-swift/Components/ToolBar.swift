import SwiftUI


// 定义一个可识别的页面枚举
enum Destination: String, Identifiable {
    case rental, plans, account, settings

    var id: String { self.rawValue }
}

struct ToolBar: View {
    @State private var selectedTab: String = "RENTAL"
    @State private var navigateTo: Destination? = nil

    var body: some View {
        HStack {
            // Tool Bar Item: RENTAL
            ToolBarItem(icon: "car.fill", title: "RENTAL", isSelected: selectedTab == "RENTAL") {
                selectedTab = "RENTAL"
                navigateTo = .rental
            }
            
            Spacer()

            // Tool Bar Item: PLANS
            ToolBarItem(icon: "arrow.2.squarepath", title: "PLANS", isSelected: selectedTab == "PLANS") {
                selectedTab = "PLANS"
                navigateTo = .plans
            }
            
            Spacer()

            // Tool Bar Item: ACCOUNT
            ToolBarItem(icon: "person.crop.circle", title: "ACCOUNT", isSelected: selectedTab == "ACCOUNT") {
                selectedTab = "ACCOUNT"
                navigateTo = .account
            }
            
            Spacer()

            // Tool Bar Item: SETTINGS
            ToolBarItem(icon: "gearshape.fill", title: "SETTINGS", isSelected: selectedTab == "SETTINGS") {
                selectedTab = "SETTINGS"
                navigateTo = .settings
            }
        }
        .frame(width: 300, height: 50)
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial)
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 2, y: 2)
        .fullScreenCover(item: $navigateTo) { destination in
            switch destination {
            case .rental:
                Rental()
            case .plans:
                Plans()
            case .account:
                Account()
            case .settings:
                Settings()
            }
        }
    }
}

// 自定义 ToolBarItem 组件
struct ToolBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isSelected ? Color("Primary1") : Color.gray)
            Text(title)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(isSelected ? Color("Primary1") : Color.gray)
        }
        .onTapGesture {
            action()
        }
    }
}

#Preview {
    ZStack {
        ScrollView(.vertical, showsIndicators: false) {
            Image("VeygoLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .ignoresSafeArea(edges: .all)
            Image("VeygoLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .ignoresSafeArea(edges: .all)
            Image("VeygoLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .ignoresSafeArea(edges: .all)
            Image("VeygoLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .ignoresSafeArea(edges: .all)
            Image("VeygoLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .ignoresSafeArea(edges: .all)
            Image("VeygoLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .ignoresSafeArea(edges: .all)
            
        }
        ToolBar()
    }
}
