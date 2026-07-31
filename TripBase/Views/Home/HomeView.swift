import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(filter: #Predicate<Trip> { !$0.isTemplate }, sort: \Trip.createdAt) private var trips: [Trip]
    @State private var isNewLegPresented = false
    @State private var isEditLegPresented = false
    @State private var isNewTripPresented = false
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
                        nextActionCard(trip: relevantTrip, leg: currentOrNextLeg)
                            .id(flightCheckinRefreshToken)
                        countdownCard(trip: relevantTrip, leg: currentOrNextLeg)
                        todayScheduleCard(trip: relevantTrip, leg: currentOrNextLeg)
                        actionChecklistCard(trip: relevantTrip, leg: currentOrNextLeg)
                            .id(flightCheckinRefreshToken)
                        packingProgressCard(trip: relevantTrip)
                        contextInfoCard(leg: currentOrNextLeg)
                        quickActionsCard(trip: relevantTrip, leg: currentOrNextLeg)
                    } else if let recentTrip = TripStatusService.mostRecentlyCompletedTrip(in: trips) {
                        recentTripSection(trip: recentTrip)
                    } else {
                        emptyStateSection
                    }
                }
                .padding()
            }
            .contentMargins(.bottom, 90, for: .scrollContent)
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
            .sheet(isPresented: $isNewTripPresented) {
                TripEditorView(existingTrip: nil)
            }
            .task(id: reminderSchedulingKey) {
                await scheduleReminders()
            }
        }
    }

    private var reminderSchedulingKey: String {
        guard let relevantTrip else { return "none" }
        let packingRemaining = relevantTrip.packingItems.filter { !$0.isChecked }.count
        let docsUnconfirmed = DocumentService.unconfirmedCount(relevantTrip.documents)
        return "\(relevantTrip.id)-\(packingRemaining)-\(docsUnconfirmed)"
    }

    private func scheduleReminders() async {
        guard let relevantTrip, let firstArrival = relevantTrip.legs.map(\.arrivalDate).min() else { return }
        let tripID = relevantTrip.id
        let tripName = relevantTrip.name
        let packingRemaining = relevantTrip.packingItems.filter { !$0.isChecked }.count
        let docsUnconfirmed = DocumentService.unconfirmedCount(relevantTrip.documents)
        await NotificationScheduler.scheduleDepartureReminders(
            tripID: tripID,
            tripName: tripName,
            firstArrivalDate: firstArrival,
            packingRemainingCount: packingRemaining,
            documentsUnconfirmedCount: docsUnconfirmed
        )
    }

    private func recentTripSection(trip: Trip) -> some View {
        VStack(spacing: 14) {
            NavigationLink {
                TripDetailView(trip: trip)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        StatusBadge(title: "最近の出張", color: .secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Text(trip.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let lastDeparture = trip.legs.map(\.departureDate).max() {
                        Text("\(AppDateFormatter.date.string(from: lastDeparture))に帰国")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle(padding: 14)
            }
            .pressableCardStyle()

            NavigationLink {
                TripListView(initialStatusFilter: .completed)
            } label: {
                HStack {
                    Label("出張履歴を見る", systemImage: "clock.arrow.circlepath")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .foregroundStyle(.primary)
                .cardStyle(padding: 14)
            }
            .pressableCardStyle()

            Button {
                isNewTripPresented = true
            } label: {
                Label("次の出張を追加", systemImage: "plus.circle.fill")
            }
            .buttonStyle(LargeActionButtonStyle())
        }
    }

    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "出張の予定がありません",
                systemImage: "airplane",
                description: Text("出張を登録すると、準備状況やスケジュールがここに表示されます。")
            )
            Button {
                isNewTripPresented = true
            } label: {
                Label("出張を追加", systemImage: "plus.circle.fill")
            }
            .buttonStyle(LargeActionButtonStyle())
        }
    }

    private func nextActionCard(trip: Trip, leg: TripLeg) -> some View {
        let key = HomeActionService.flightCheckinKey(tripID: trip.id, legID: leg.id)
        let flightCheckinDone = UserDefaults.standard.bool(forKey: key)
        let action = HomeActionService.topPriorityAction(trip: trip, leg: leg, flightCheckinDone: flightCheckinDone)

        return Group {
            if let action {
                nextActionButton(action: action, trip: trip, leg: leg)
            } else {
                allDoneCard
            }
        }
    }

    @ViewBuilder
    private func nextActionButton(action: HomeActionItem, trip: Trip, leg: TripLeg) -> some View {
        switch (action.kind, action.id) {
        case (.toggle, _):
            Button {
                let key = HomeActionService.flightCheckinKey(tripID: trip.id, legID: leg.id)
                UserDefaults.standard.set(true, forKey: key)
                HapticsService.success()
                flightCheckinRefreshToken = UUID()
            } label: {
                nextActionLabel(action: action)
            }
            .pressableCardStyle()
        case (_, "hotel"), (_, "visa"), (_, "transport"):
            Button {
                isEditLegPresented = true
            } label: {
                nextActionLabel(action: action)
            }
            .pressableCardStyle()
        case (_, "packing"):
            NavigationLink {
                PackingHomeView()
            } label: {
                nextActionLabel(action: action)
            }
            .pressableCardStyle()
        case (_, "tasks"):
            NavigationLink {
                TripTaskListView(trip: trip)
            } label: {
                nextActionLabel(action: action)
            }
            .pressableCardStyle()
        default:
            NavigationLink {
                TripDetailView(trip: trip)
            } label: {
                nextActionLabel(action: action)
            }
            .pressableCardStyle()
        }
    }

    private func nextActionLabel(action: HomeActionItem) -> some View {
        HStack(spacing: 14) {
            Image(systemName: action.systemImage)
                .font(.title2)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 40, height: 40)
                .background(AppTheme.accent.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("次にやること")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Text(action.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1.5)
        }
        .shadow(color: AppTheme.cardShadowColor, radius: AppTheme.cardShadowRadius, y: AppTheme.cardShadowY)
    }

    private var allDoneCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 40, height: 40)
                .background(AppTheme.accent.opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("準備完了です")
                    .font(.headline)
                Text("未完了の準備はありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.accent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
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
                HapticsService.lightImpact()
                flightCheckinRefreshToken = UUID()
            } label: {
                actionRowLabel(item: item)
            }
            .pressableCardStyle()
        case .navigate where item.id == "hotel" && item.isDone:
            NavigationLink {
                DestinationInfoView(leg: leg)
            } label: {
                actionRowLabel(item: item)
            }
            .pressableCardStyle()
        case .navigate where item.id == "hotel" || item.id == "visa" || item.id == "transport":
            Button {
                isEditLegPresented = true
            } label: {
                actionRowLabel(item: item)
            }
            .pressableCardStyle()
        case .navigate:
            NavigationLink {
                destination(for: item, trip: trip, leg: leg)
            } label: {
                actionRowLabel(item: item)
            }
            .pressableCardStyle()
        }
    }

    private func actionRowLabel(item: HomeActionItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isDone ? AppTheme.accent : .secondary)
            Image(systemName: item.systemImage)
                .foregroundStyle(item.isDone ? AppTheme.accent : .secondary)
                .frame(width: 18)
            Text(item.title)
                .foregroundStyle(item.isDone ? AppTheme.accent : .primary)
            Spacer()
            if item.kind == .navigate {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .font(.subheadline)
        .padding(.vertical, 6)
        .padding(.horizontal, item.isDone ? 8 : 0)
        .background(item.isDone ? AppTheme.accent.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func destination(for item: HomeActionItem, trip: Trip, leg: TripLeg) -> some View {
        switch item.id {
        case "packing":
            PackingHomeView()
        case "tasks":
            TripTaskListView(trip: trip)
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

                if phase == .inProgress {
                    if let dayNumber = TripStatusService.dayNumber(of: trip),
                       let totalDays = TripStatusService.tripDurationDays(of: trip) {
                        Text("出張\(dayNumber)日目 / 全\(totalDays)日")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.accent)
                    }
                    if let daysLeft = TripStatusService.daysUntilReturn(of: trip) {
                        Text(daysLeft == 0 ? "本日帰国予定" : "帰国まであと\(daysLeft)日")
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.accent)
                    }
                } else if let daysLeft = TripStatusService.daysUntilDeparture(of: trip) {
                    Text(daysLeft == 0 ? "本日出発" : "出発まであと\(daysLeft)日")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(AppTheme.accent.opacity(0.11))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .shadow(color: AppTheme.cardShadowColor, radius: AppTheme.cardShadowRadius, y: AppTheme.cardShadowY)
        }
        .pressableCardStyle()
    }

    private func todayScheduleCard(trip: Trip, leg: TripLeg) -> some View {
        let phase = TripStatusService.phase(of: trip)
        let headerTitle = phase == .inProgress ? "今日の予定" : "次の目的地"

        return NavigationLink {
            TripDetailView(trip: trip)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(headerTitle, systemImage: "calendar")
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
        .pressableCardStyle()
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
                .pressableCardStyle()

                NavigationLink {
                    WeatherView()
                } label: {
                    CompactWeatherView(leg: leg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .pressableCardStyle()
            }
            Divider()
            NavigationLink {
                ForexView()
            } label: {
                CompactForexView(leg: leg)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .pressableCardStyle()
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
        .pressableCardStyle()
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
        .pressableCardStyle()
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
