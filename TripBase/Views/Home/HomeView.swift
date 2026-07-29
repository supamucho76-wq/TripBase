import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \Trip.createdAt) private var trips: [Trip]
    @State private var isNewLegPresented = false
    @State private var isEditLegPresented = false
    @State private var flightCheckinRefreshToken = UUID()

    private var relevantTrip: Trip? {
        TripStatusService.activeTrip(in: trips) ?? TripStatusService.nextUpcomingTrip(in: trips)
    }

    private var currentOrNextLeg: TripLeg? {
        guard let relevantTrip else { return nil }
        return TripStatusService.currentLeg(in: relevantTrip.legs)
            ?? TripStatusService.nextLeg(in: relevantTrip.legs)
            ?? relevantTrip.legs.sorted { $0.orderIndex < $1.orderIndex }.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    header

                    if let relevantTrip, let currentOrNextLeg {
                        actionChecklistCard(trip: relevantTrip, leg: currentOrNextLeg)
                            .id(flightCheckinRefreshToken)
                        countdownCard(trip: relevantTrip, leg: currentOrNextLeg)
                        todayScheduleCard(trip: relevantTrip, leg: currentOrNextLeg)
                        contextInfoCard(leg: currentOrNextLeg)
                        packingProgressCard(trip: relevantTrip)
                        quickActionsCard(trip: relevantTrip, leg: currentOrNextLeg)
                    } else {
                        ContentUnavailableView(
                            "出張の予定がありません",
                            systemImage: "airplane",
                            description: Text("「出張」タブから行程を追加してください。")
                        )
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("出張Base")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isNewLegPresented) {
                if let relevantTrip {
                    TripLegEditorView(
                        trip: relevantTrip,
                        existingLeg: nil,
                        nextOrderIndex: relevantTrip.legs.count
                    )
                }
            }
            .sheet(isPresented: $isEditLegPresented) {
                if let relevantTrip, let currentOrNextLeg {
                    TripLegEditorView(
                        trip: relevantTrip,
                        existingLeg: currentOrNextLeg,
                        nextOrderIndex: relevantTrip.legs.count
                    )
                }
            }
        }
    }

    private func actionChecklistCard(trip: Trip, leg: TripLeg) -> some View {
        let key = HomeActionService.flightCheckinKey(tripID: trip.id, legID: leg.id)
        let flightCheckinDone = UserDefaults.standard.bool(forKey: key)
        let items = HomeActionService.actionItems(trip: trip, leg: leg, flightCheckinDone: flightCheckinDone)
        let remainingCount = items.filter { !$0.isDone }.count

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("今日やること", systemImage: "checklist.checked")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                if !items.isEmpty {
                    Text(remainingCount == 0 ? "準備完了" : "残り\(remainingCount)件")
                        .font(.caption.bold())
                        .foregroundStyle(remainingCount == 0 ? AppTheme.accent : .secondary)
                }
            }
            if items.isEmpty {
                Text("やることはありません")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    actionRow(item: item, trip: trip, leg: leg)
                    if index != items.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 14)
    }

    @ViewBuilder
    private func actionRow(item: HomeActionItem, trip: Trip, leg: TripLeg) -> some View {
        switch item.kind {
        case .toggle:
            Button {
                let key = HomeActionService.flightCheckinKey(tripID: trip.id, legID: leg.id)
                UserDefaults.standard.set(!item.isDone, forKey: key)
                flightCheckinRefreshToken = UUID()
            } label: {
                actionRowLabel(item: item)
            }
            .buttonStyle(.plain)
        case .navigate where item.id == "hotel" || item.id == "visa":
            Button {
                isEditLegPresented = true
            } label: {
                actionRowLabel(item: item)
            }
            .buttonStyle(.plain)
        case .navigate:
            NavigationLink {
                destination(for: item, leg: leg)
            } label: {
                actionRowLabel(item: item)
            }
            .buttonStyle(.plain)
        }
    }

    private func actionRowLabel(item: HomeActionItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isDone ? AppTheme.accent : .secondary)
            Image(systemName: item.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(item.title)
                .foregroundStyle(.primary)
                .strikethrough(item.isDone)
            Spacer()
            if item.kind == .navigate {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .font(.subheadline)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func destination(for item: HomeActionItem, leg: TripLeg) -> some View {
        switch item.id {
        case "packing":
            PackingHomeView()
        default:
            DestinationInfoView(leg: leg)
        }
    }

    private var header: some View {
        HStack {
            Text(Date.now.formatted(.dateTime.month().day().weekday(.wide)))
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Image(systemName: "airplane.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(AppTheme.accent)
        }
    }

    private func countdownCard(trip: Trip, leg: TripLeg) -> some View {
        let phase = TripStatusService.phase(of: trip)
        let sortedLegs = trip.legs.sorted { $0.arrivalDate < $1.arrivalDate }

        return NavigationLink {
            TripDetailView(trip: trip)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    StatusBadge(title: phase == .inProgress ? "出張中" : "出張予定", color: AppTheme.accent)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent.opacity(0.6))
                }
                Text(trip.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if phase == .inProgress, let lastDeparture = sortedLegs.map(\.departureDate).max() {
                    let daysLeft = max(0, Calendar.current.dateComponents([.day], from: .now, to: lastDeparture).day ?? 0)
                    Text("帰国まであと\(daysLeft)日")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.accent)
                } else if let firstArrival = sortedLegs.map(\.arrivalDate).min() {
                    let daysLeft = max(0, Calendar.current.dateComponents([.day], from: .now, to: firstArrival).day ?? 0)
                    Text("出発まであと\(daysLeft)日")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.accent.opacity(0.11))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func todayScheduleCard(trip: Trip, leg: TripLeg) -> some View {
        NavigationLink {
            TripDetailView(trip: trip)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("今日の予定", systemImage: "calendar")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(leg.cityName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(CountryInfoStore.displayName(for: leg.countryCode))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !leg.hotelName.isEmpty {
                    Label(leg.hotelName, systemImage: "bed.double")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("\(AppDateFormatter.shortDate.string(from: leg.arrivalDate)) 〜 \(AppDateFormatter.shortDate.string(from: leg.departureDate))（\(leg.nightsCount)泊）")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(padding: 14)
        }
        .buttonStyle(.plain)
    }

    private func contextInfoCard(leg: TripLeg) -> some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 16) {
                NavigationLink {
                    TimezoneOverviewView()
                } label: {
                    CompactTimezoneView(leg: leg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    WeatherView()
                } label: {
                    CompactWeatherView(leg: leg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            Divider()
            NavigationLink {
                ForexView()
            } label: {
                CompactForexView(leg: leg)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .cardStyle(padding: 14)
    }

    private func packingProgressCard(trip: Trip) -> some View {
        let items = trip.packingItems
        let percent = PackingService.percentComplete(items)
        let checkedCount = items.filter(\.isChecked).count

        return NavigationLink {
            PackingHomeView()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label("持ち物", systemImage: "checklist")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                ProgressView(value: percent)
                    .tint(AppTheme.accent)
                Text(items.isEmpty ? "まだ持ち物が登録されていません" : "\(checkedCount)/\(items.count)完了")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(padding: 14)
        }
        .buttonStyle(.plain)
    }

    private func quickActionsCard(trip: Trip, leg: TripLeg) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("クイックアクション")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Button {
                    isNewLegPresented = true
                } label: {
                    quickActionLabel("行程を追加", systemImage: "plus.circle")
                }

                NavigationLink {
                    TripDetailView(trip: trip)
                } label: {
                    quickActionLabel("出張詳細", systemImage: "doc.text.magnifyingglass")
                }

                NavigationLink {
                    DestinationInfoView(leg: leg)
                } label: {
                    quickActionLabel("現地情報", systemImage: "mappin.and.ellipse")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 14)
        .buttonStyle(.plain)
    }

    private func quickActionLabel(_ title: String, systemImage: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.title3)
            Text(title)
                .font(.caption2)
        }
        .foregroundStyle(AppTheme.accent)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppTheme.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    HomeView()
}
