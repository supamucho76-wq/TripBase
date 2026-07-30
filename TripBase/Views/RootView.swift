import SwiftUI

struct RootView: View {
    @State private var selection: TripBaseTab = .home
    @AppStorage(AppearancePreference.storageKey) private var appearanceRawValue: String = AppearancePreference.system.rawValue

    private var appearance: AppearancePreference {
        AppearancePreference(rawValue: appearanceRawValue) ?? .system
    }

    var body: some View {
        Group {
            switch selection {
            case .home: HomeView()
            case .trips: NavigationStack { TripListView() }
            case .packing: NavigationStack { PackingHomeView() }
            case .more: MoreView()
            case .settings: NavigationStack { SettingsView() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingTabBar(selection: $selection)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .preferredColorScheme(appearance.colorScheme)
    }
}

#Preview {
    RootView()
}
