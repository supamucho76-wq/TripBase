import SwiftUI

struct RootView: View {
    @State private var selection: TripBaseTab = .home

    var body: some View {
        Group {
            switch selection {
            case .home: HomeView()
            case .trips: NavigationStack { TripListView() }
            case .calendar: CalendarView()
            case .documents: DocumentsHomeView()
            case .more: MoreView()
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
