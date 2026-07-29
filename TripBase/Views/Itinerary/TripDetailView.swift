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

    private var representativeLeg: TripLeg? {
        TripStatusService.currentLeg(in: trip.legs)
            ?? TripStatusService.nextLeg(in: trip.legs)
            ?? sortedLegs.first
    }

    private var phaseTitle: String {
        switch TripStatusService.phase(of: trip) {
        case .noItinerary: "未設定"
        case .upcoming: "予定"
        case .inProgress: "進行中"
        case .completed: "完了"
        }
    }

    private var packingSummaryText: String {
        let items = trip.packingItems
        guard !items.isEmpty else { return "未登録" }
        return "\(items.filter(\.isChecked).count)/\(items.count)完了"
    }

    var body: some View {
        List {
            Section {
                summaryCard
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            if let representativeLeg {
                Section("現在の状況") {
                    contextRow(leg: representativeLeg)
                    NavigationLink {
                        DestinationInfoView(leg: representativeLeg)
                    } label: {
                        Label("\(representativeLeg.cityName)の現地情報を見る", systemImage: "mappin.and.ellipse")
                    }
                }
            }

            Section("持ち物・書類") {
                NavigationLink {
                    PackingHomeView()
                } label: {
                    HStack {
                        Label("持ち物チェックリスト", systemImage: "checklist")
                        Spacer()
                        Text(packingSummaryText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    ContentUnavailableView(
                        "書類機能は準備中です",
                        systemImage: "doc.text",
                        description: Text("航空券・ホテル予約・パスポートなどをまとめて保存できるようになります。")
                    )
                    .navigationTitle("書類")
                } label: {
                    Label("書類", systemImage: "doc.text")
                }
            }

            Section("タスク・メモ") {
                NavigationLink {
                    ContentUnavailableView(
                        "タスク機能は準備中です",
                        systemImage: "checkmark.circle",
                        description: Text("出張前後にやることをリストで管理できるようになります。")
                    )
                    .navigationTitle("タスク")
                } label: {
                    Label("タスク", systemImage: "checkmark.circle")
                }
                NavigationLink {
                    ContentUnavailableView(
                        "メモ機能は準備中です",
                        systemImage: "note.text",
                        description: Text("出張中の気づきや次回への引き継ぎをメモできるようになります。")
                    )
                    .navigationTitle("メモ")
                } label: {
                    Label("メモ", systemImage: "note.text")
                }
            }

            if sortedLegs.isEmpty {
                Section {
                    ContentUnavailableView(
                        "行程がまだありません",
                        systemImage: "mappin.and.ellipse",
                        description: Text("右上の + から目的地・宿泊先を追加できます。")
                    )
                }
            } else {
                Section("行程") {
                    ForEach(sortedLegs) { leg in
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
        }
        .contentMargins(.bottom, 90, for: .scrollContent)
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

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !trip.purpose.isEmpty {
                Text(trip.purpose)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                StatusBadge(title: phaseTitle, color: AppTheme.accent)
                if let tripType = trip.tripType {
                    Text(tripType == .domestic ? "国内" : "海外")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            if let first = sortedLegs.first, let last = sortedLegs.last {
                Text("\(AppDateFormatter.date.string(from: first.arrivalDate)) 〜 \(AppDateFormatter.date.string(from: last.departureDate))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 14)
    }

    private func contextRow(leg: TripLeg) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !leg.hotelName.isEmpty {
                Label(leg.hotelName, systemImage: "bed.double")
                    .font(.subheadline)
            }
            HStack(alignment: .top, spacing: 16) {
                CompactTimezoneView(leg: leg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                CompactWeatherView(leg: leg)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            CompactForexView(leg: leg)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
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
