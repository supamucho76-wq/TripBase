import SwiftUI

enum TripBaseTab: Int, CaseIterable, Identifiable {
    case home
    case trips
    case calendar
    case documents
    case more

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: "ホーム"
        case .trips: "出張"
        case .calendar: "カレンダー"
        case .documents: "書類"
        case .more: "その他"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .trips: "airplane"
        case .calendar: "calendar"
        case .documents: "doc.text.fill"
        case .more: "ellipsis.circle.fill"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .home: "tab.home"
        case .trips: "tab.trips"
        case .calendar: "tab.calendar"
        case .documents: "tab.documents"
        case .more: "tab.more"
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
