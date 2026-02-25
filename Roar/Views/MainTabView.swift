import SwiftUI
struct MainTabView: View {
    @State private var showCamera = false
    @State private var selectedTab: String = "ForYou"
    
    // Customizing the appearance of the Tab Bar
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.roarBlue)
        
        let itemAppearance = UITabBarItemAppearance()
        // Unselected icon color
        itemAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
        
        // Selected icon color (Gold)
        itemAppearance.selected.iconColor = UIColor(Color.roarGold)
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.roarGold)]
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForYouView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("For You")
                }
                .tag("ForYou")
                .environment(\.owningTab, "ForYou")
            
            ExploreView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explore")
                }
                .tag("Explore")
                .environment(\.owningTab, "Explore")
            
            // Camera Placeholder for Tab Layout
            CameraView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                }
                .tag("Camera")
            
            FriendsView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }
                .tag("Friends")
                .environment(\.owningTab, "Friends")
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag("Profile")
                .environment(\.owningTab, "Profile")
        }
        .accentColor(.roarGold)
        .environment(\.selectedTab, selectedTab)
    }
}

