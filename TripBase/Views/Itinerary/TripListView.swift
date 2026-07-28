import SwiftData
import SwiftUI

struct TripListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @State private var isNewTripPresented = false
    @State private var tripPendingDelete: Trip?

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    ContentUnavailableView(
                        "出張がまだありません",
                        systemImage: "airplane",
                        description: Text("右上の + から出張を追加できます。")
                    )
                } else {
                    List(trips) { trip in
                        NavigationLink(value: trip) {
                            TripRow(trip: trip)
                        }
                        .swipeActions {
                            Button("削除", role: .destructive) {
                                tripPendingDelete = trip
                            }
                        }
                    }
                }
            }
            .navigationTitle("出張一覧")
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
            .confirmationDialog(
                "この出張を削除しますか?",
                isPresented: Binding(
                    get: { tripPendingDelete != nil },
                    set: { isPresented in
                        if !isPresented { tripPendingDelete = nil }
                    }
                ),
                titleVisibility: .visible
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
}

private struct TripRow: View {
    let trip: Trip

    private var sortedLegs: [TripLeg] {
        trip.legs.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(trip.name)
                .font(.headline)
            if let first = sortedLegs.first, let last = sortedLegs.last {
                Text("\(AppDateFormatter.date.string(from: first.arrivalDate)) 〜 \(AppDateFormatter.date.string(from: last.departureDate))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("行程未登録")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("\(sortedLegs.count)行程")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
