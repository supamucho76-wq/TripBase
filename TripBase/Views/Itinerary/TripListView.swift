import SwiftData
import SwiftUI

enum TripStatusFilter: String, CaseIterable, Identifiable {
    case all
    case inProgress
    case upcoming
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "すべて"
        case .inProgress: "進行中"
        case .upcoming: "予定"
        case .completed: "完了"
        }
    }
}

enum TripRegionFilter: String, CaseIterable, Identifiable {
    case all
    case domestic
    case international

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "すべて"
        case .domestic: "国内"
        case .international: "海外"
        }
    }
}

struct TripListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Trip> { !$0.isTemplate }, sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @State private var isNewTripPresented = false
    @State private var tripPendingDelete: Trip?
    @State private var statusFilter: TripStatusFilter
    @State private var regionFilter: TripRegionFilter = .all

    init(initialStatusFilter: TripStatusFilter = .all) {
        _statusFilter = State(initialValue: initialStatusFilter)
    }

    private var filteredTrips: [Trip] {
        trips.filter { trip in
            statusMatches(trip) && regionMatches(trip)
        }
    }

    private func statusMatches(_ trip: Trip) -> Bool {
        switch statusFilter {
        case .all: true
        case .inProgress: TripStatusService.phase(of: trip) == .inProgress
        case .upcoming: TripStatusService.phase(of: trip) == .upcoming
        case .completed: TripStatusService.phase(of: trip) == .completed
        }
    }

    private func regionMatches(_ trip: Trip) -> Bool {
        switch regionFilter {
        case .all: true
        case .domestic: trip.tripType == .domestic
        case .international: trip.tripType == .international
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker("ステータス", selection: $statusFilter) {
                ForEach(TripStatusFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Picker("地域", selection: $regionFilter) {
                ForEach(TripRegionFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Group {
                if filteredTrips.isEmpty {
                    ContentUnavailableView(
                        trips.isEmpty ? "出張がまだありません" : "該当する出張がありません",
                        systemImage: "airplane",
                        description: Text(trips.isEmpty ? "右上の + から出張を追加できます。" : "フィルタ条件を変えてみてください。")
                    )
                } else {
                    List(filteredTrips) { trip in
                        NavigationLink(value: trip) {
                            TripRow(trip: trip)
                        }
                        .swipeActions {
                            Button("削除", role: .destructive) {
                                tripPendingDelete = trip
                            }
                        }
                    }
                    .listStyle(.plain)
                    .contentMargins(.bottom, 90, for: .scrollContent)
                }
            }
        }
        .navigationTitle("出張一覧")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Trip.self) { trip in
            TripDetailView(trip: trip)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isNewTripPresented = true
                } label: {
                    Label("出張を追加", systemImage: "plus")
                }
                .accessibilityIdentifier("trip.add")
            }
        }
        .sheet(isPresented: $isNewTripPresented) {
            TripEditorView(existingTrip: nil)
        }
        .alert(
            "この出張を削除しますか？",
            isPresented: Binding(
                get: { tripPendingDelete != nil },
                set: { isPresented in
                    if !isPresented { tripPendingDelete = nil }
                }
            )
        ) {
            Button("削除", role: .destructive) {
                if let trip = tripPendingDelete {
                    modelContext.delete(trip)
                }
                tripPendingDelete = nil
            }
            Button("キャンセル", role: .cancel) {
                tripPendingDelete = nil
            }
        } message: {
            Text("旅程・宿泊情報もすべて削除され、元に戻せません。")
        }
    }
}

private struct TripRow: View {
    let trip: Trip

    private var sortedLegs: [TripLeg] {
        trip.legs.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var phase: TripPhase {
        TripStatusService.phase(of: trip)
    }

    private var phaseBadgeColor: Color {
        switch phase {
        case .noItinerary: .secondary
        case .upcoming: AppTheme.accent
        case .inProgress: AppTheme.accent
        case .completed: .secondary
        }
    }

    private var phaseTitle: String {
        switch phase {
        case .noItinerary: "未設定"
        case .upcoming: "予定"
        case .inProgress: "進行中"
        case .completed: "完了"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(trip.name)
                    .font(.headline)
                Spacer()
                StatusBadge(title: phaseTitle, color: phaseBadgeColor)
            }
            if let first = sortedLegs.first, let last = sortedLegs.last {
                HStack(spacing: 6) {
                    Text("\(AppDateFormatter.date.string(from: first.arrivalDate)) 〜 \(AppDateFormatter.date.string(from: last.departureDate))")
                    if let tripType = trip.tripType {
                        Text(tripType == .domestic ? "・国内" : "・海外")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            } else {
                Text("行程未登録")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("行程\(sortedLegs.count)件")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
