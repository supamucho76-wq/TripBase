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

    private var documentSummaryText: String {
        let documents = trip.documents
        guard !documents.isEmpty else { return "未登録" }
        let unconfirmed = DocumentService.unconfirmedCount(documents)
        return unconfirmed == 0 ? "確認済み" : "未確認\(unconfirmed)件"
    }

    private var taskSummaryText: String {
        let tasks = trip.tasks
        guard !tasks.isEmpty else { return "未登録" }
        let remaining = tasks.filter { !$0.isDone }.count
        return remaining == 0 ? "すべて完了" : "残り\(remaining)件"
    }

    private var noteSummaryText: String {
        trip.notesList.isEmpty ? "未登録" : "\(trip.notesList.count)件"
    }

    private var perDiemSummaryText: String {
        guard let rule = trip.perDiemRule, let durationDays = TripStatusService.tripDurationDays(of: trip) else {
            return "未設定"
        }
        let total = PerDiemCalculator.total(rule: rule, tripDurationDays: durationDays)
        return "\(total.formatted(.number.precision(.fractionLength(0...2)))) \(rule.currencyCode)"
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
                    TripDocumentListView(trip: trip)
                } label: {
                    HStack {
                        Label("書類", systemImage: "doc.text")
                        Spacer()
                        Text(documentSummaryText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("タスク・メモ") {
                NavigationLink {
                    TripTaskListView(trip: trip)
                } label: {
                    HStack {
                        Label("タスク", systemImage: "checkmark.circle")
                        Spacer()
                        Text(taskSummaryText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink {
                    TripNoteListView(trip: trip)
                } label: {
                    HStack {
                        Label("メモ", systemImage: "note.text")
                        Spacer()
                        Text(noteSummaryText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                NavigationLink {
                    PerDiemView(trip: trip)
                } label: {
                    HStack {
                        Label("日当計算（参考）", systemImage: "yensign.circle")
                        Spacer()
                        Text(perDiemSummaryText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("参考値です。正式な支給額は勤務先の規定をご確認ください。")
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
                Section {
                    ForEach(sortedLegs) { leg in
                        HStack(spacing: 8) {
                            NavigationLink(value: leg) {
                                TripLegRow(leg: leg)
                            }
                            Button {
                                legPendingEdit = leg
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(leg.cityName)の行程を編集")
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
                } header: {
                    Text("行程")
                } footer: {
                    Text("行程をタップすると現地情報、鉛筆アイコンをタップすると編集画面が開きます。")
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
        .alert(
            "この行程を削除しますか？",
            isPresented: Binding(
                get: { legPendingDelete != nil },
                set: { isPresented in
                    if !isPresented { legPendingDelete = nil }
                }
            )
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
