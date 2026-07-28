import SwiftUI

enum TripBaseTab: Int, CaseIterable, Identifiable {
    case home
    case itinerary
    case weather
    case forex
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: "ホーム"
        case .itinerary: "出張"
        case .weather: "天気"
        case .forex: "為替"
        case .settings: "設定"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .itinerary: "airplane"
        case .weather: "cloud.sun.fill"
        case .forex: "yensign.circle.fill"
        case .settings: "gearshape.fill"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .home: "tab.home"
        case .itinerary: "tab.itinerary"
        case .weather: "tab.weather"
        case .forex: "tab.forex"
        case .settings: "tab.settings"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: TripBaseTab

    var body: some View {
        HStack {
            ForEach(TripBaseTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 20))
                        Text(tab.title)
                            .font(.caption2)
                    }
                    .foregroundStyle(selection == tab ? AppTheme.accent : .secondary)
                    .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier(tab.accessibilityIdentifier)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            AppTheme.background
                .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
