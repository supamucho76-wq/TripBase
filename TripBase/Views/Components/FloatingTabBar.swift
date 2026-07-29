import SwiftUI

enum TripBaseTab: Int, CaseIterable, Identifiable {
    case home
    case trips
    case packing
    case more
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: "ホーム"
        case .trips: "出張"
        case .packing: "持ち物"
        case .more: "ツール"
        case .settings: "設定"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .trips: "airplane"
        case .packing: "checklist"
        case .more: "wrench.and.screwdriver.fill"
        case .settings: "gearshape.fill"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .home: "tab.home"
        case .trips: "tab.trips"
        case .packing: "tab.packing"
        case .more: "tab.more"
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
