import SwiftData
import SwiftUI

struct TripDetailView: View {
    @Bindable var trip: Trip

    @Environment(\.modelContext) private var modelContext
    @State private var isNewLegPresented = false
    @State private var legPendingEdit: TripLeg?
    @State private var legPendingDelete: TripLeg?
    @State private var isTripEditorPresented = false

    private var sortedLegs: [TripLeg] {
        trip.legs.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        Group {
            if sortedLegs.isEmpty {
                ContentUnavailableView(
                    "行程がまだありません",
                    systemImage: "mappin.and.ellipse",
                    description: Text("右上の + から目的地・宿泊先を追加できます。")
                )
            } else {
                List(sortedLegs) { leg in
                    NavigationLink(value: leg) {
                        TripLegRow(leg: leg)
                    }
                    .swipeActions {
                        Button("削除", role: .destructive) {
                            legPendingDelete = leg
                        }
                        Button("編集") {
                            legPendingEdit = leg
                        }
                        .tint(AppTheme.accent)
                    }
                }
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: TripLeg.self) { leg in
            DestinationInfoView(leg: leg)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isNewLegPresented = true
                } label: {
                    Label("行程を追加", systemImage: "plus")
                }
                .accessibilityIdentifier("trip.leg.add")
            }
            ToolbarItem(placement: .secondaryAction) {
                Button("出張情報を編集") {
                    isTripEditorPresented = true
                }
            }
        }
        .sheet(isPresented: $isNewLegPresented) {
            TripLegEditorView(trip: trip, existingLeg: nil, nextOrderIndex: sortedLegs.count)
        }
        .sheet(item: $legPendingEdit) { leg in
            TripLegEditorView(trip: trip, existingLeg: leg, nextOrderIndex: leg.orderIndex)
        }
        .sheet(isPresented: $isTripEditorPresented) {
            TripEditorView(existingTrip: trip)
        }
        .confirmationDialog(
            "この行程を削除しますか?",
            isPresented: Binding(
                get: { legPendingDelete != nil },
                set: { isPresented in
                    if !isPresented { legPendingDelete = nil }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                if let leg = legPendingDelete {
                    modelContext.delete(leg)
                }
                legPendingDelete = nil
            }
            Button("キャンセル", role: .cancel) {
                legPendingDelete = nil
            }
        } message: {
            Text("削除すると元に戻せません。")
        }
    }
}

private struct TripLegRow: View {
    let leg: TripLeg

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(leg.cityName)
                    .font(.headline)
                Text(leg.countryCode)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                StatusBadge(title: leg.visaStatus.title, color: AppTheme.accent)
            }
            Text("\(AppDateFormatter.date.string(from: leg.arrivalDate)) 〜 \(AppDateFormatter.date.string(from: leg.departureDate))（\(leg.nightsCount)泊）")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !leg.hotelName.isEmpty {
                Label(leg.hotelName, systemImage: "bed.double")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .foregroundStyle(.primary)
    }
}
