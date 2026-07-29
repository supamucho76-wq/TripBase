import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \Trip.createdAt) private var trips: [Trip]
    @State private var isNewLegPresented = false

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
                        countdownCard(trip: relevantTrip, leg: currentOrNextLeg)
                        todayScheduleCard(leg: currentOrNextLeg)
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

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                StatusBadge(title: phase == .inProgress ? "出張中" : "出張予定", color: AppTheme.accent)
                Spacer()
            }
            Text(trip.name)
                .font(.headline)

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

    private func todayScheduleCard(leg: TripLeg) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("今日の予定", systemImage: "calendar")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(leg.cityName)
                    .font(.headline)
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

    private func contextInfoCard(leg: TripLeg) -> some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 16) {
                CompactTimezoneView(leg: leg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                CompactWeatherView(leg: leg)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            CompactForexView(leg: leg)
                .frame(maxWidth: .infinity, alignment: .leading)
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
