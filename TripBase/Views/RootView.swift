import SwiftUI

struct RootView: View {
    @State private var selection: TripBaseTab = .home

    var body: some View {
        Group {
            switch selection {
            case .home: HomeView()
            case .itinerary: TripListView()
            case .weather: WeatherView()
            case .forex: ForexView()
            case .settings: SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingTabBar(selection: $selection)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

#Preview {
    RootView()
}
