import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house") }
            TripListView()
                .tabItem { Label("出張", systemImage: "airplane") }
        }
        .tint(AppTheme.accent)
    }
}

#Preview {
    RootView()
}
