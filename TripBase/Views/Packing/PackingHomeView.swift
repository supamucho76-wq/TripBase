import SwiftData
import SwiftUI

struct PackingHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @State private var selectedTripID: UUID?
    @State private var newItemName = ""
    @State private var newItemCategory: PackingCategory = .misc
    @State private var itemsPendingDelete: [PackingItem]?

    private var relevantTrips: [Trip] {
        trips.filter {
            let phase = TripStatusService.phase(of: $0)
            return phase == .inProgress || phase == .upcoming
        }
    }

    private var selectedTrip: Trip? {
        if let selectedTripID, let match = relevantTrips.first(where: { $0.id == selectedTripID }) {
            return match
        }
        return TripStatusService.activeTrip(in: trips) ?? TripStatusService.nextUpcomingTrip(in: trips)
    }

    private func sortedItems(for trip: Trip) -> [PackingItem] {
        trip.packingItems.sorted { $0.orderIndex < $1.orderIndex }
    }

    private func groupedItems(for trip: Trip) -> [(category: PackingCategory, items: [PackingItem])] {
        let items = sortedItems(for: trip)
        return PackingCategory.allCases.compactMap { category in
            let matching = items.filter { $0.category == category }
            return matching.isEmpty ? nil : (category, matching)
        }
    }

    var body: some View {
        Group {
            if let trip = selectedTrip {
                packingList(for: trip)
            } else {
                ContentUnavailableView(
                    "出張の予定がありません",
                    systemImage: "checklist",
                    description: Text("「出張」タブから出張を登録すると、持ち物リストが使えます。")
                )
            }
        }
        .navigationTitle("持ち物")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if relevantTrips.count > 1 {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(relevantTrips) { trip in
                            Button(trip.name) { selectedTripID = trip.id }
                        }
                    } label: {
                        Label("出張を選択", systemImage: "chevron.down.circle")
                    }
                }
            }
        }
    }

    private func packingList(for trip: Trip) -> some View {
        let percent = PackingService.percentComplete(trip.packingItems)
        let checkedCount = trip.packingItems.filter(\.isChecked).count
        let remainingCount = trip.packingItems.count - checkedCount
        let isUrgent = PackingService.isUrgent(trip: trip)

        return List {
            Section {
                VStack(spacing: 8) {
                    Text(trip.name)
                        .font(.headline)
                    if !trip.packingItems.isEmpty {
                        CircularProgressRing(progress: percent)
                        Text(percent >= 1 ? "準備完了！" : "残り\(remainingCount)件")
                            .font(.title3.bold())
                            .foregroundStyle(percent >= 1 ? AppTheme.accent : (isUrgent ? AppTheme.danger : .primary))
                        if percent >= 1 {
                            Label("すべて準備できました", systemImage: "party.popper.fill")
                                .font(.footnote.bold())
                                .foregroundStyle(AppTheme.accent)
                                .transition(.scale.combined(with: .opacity))
                        }
                        if isUrgent && remainingCount > 0 {
                            Label("出発が近づいています。残り\(remainingCount)件を確認してください", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.danger)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .animation(.spring(response: 0.45, dampingFraction: 0.7), value: percent >= 1)
            }

            if trip.packingItems.isEmpty {
                Section {
                    ForEach(PackingService.recommendedTemplates(for: trip.tripType)) { template in
                        Button(template.title) {
                            applyTemplate(template, to: trip)
                        }
                    }
                } header: {
                    Text("テンプレートから追加")
                } footer: {
                    if let tripType = trip.tripType {
                        Text(tripType == .domestic ? "国内出張として、必要な持ち物のみ表示しています。" : "海外出張として、必要な持ち物のみ表示しています。")
                    }
                }
            }

            ForEach(groupedItems(for: trip), id: \.category) { group in
                Section {
                    ForEach(group.items) { item in
                        Button {
                            toggle(item)
                        } label: {
                            HStack {
                                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isChecked ? .secondary : (isUrgent ? AppTheme.danger : .primary))
                                Text(item.name)
                                    .foregroundStyle(item.isChecked ? .secondary : (isUrgent ? AppTheme.danger : .primary))
                                Spacer()
                            }
                            .opacity(item.isChecked ? 0.55 : 1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        itemsPendingDelete = offsets.map { group.items[$0] }
                    }
                } header: {
                    categoryHeader(group: group)
                }
            }

            Section("追加") {
                HStack {
                    TextField("持ち物を追加", text: $newItemName)
                    Picker("カテゴリ", selection: $newItemCategory) {
                        ForEach(PackingCategory.allCases) { category in
                            Label(category.title, systemImage: category.systemImage).tag(category)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    Button {
                        addItem(to: trip)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("持ち物を追加する")
                    .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .contentMargins(.bottom, 90, for: .scrollContent)
        .alert(
            "この持ち物を削除しますか？",
            isPresented: Binding(
                get: { itemsPendingDelete != nil },
                set: { isPresented in
                    if !isPresented { itemsPendingDelete = nil }
                }
            )
        ) {
            Button("削除", role: .destructive) {
                if let items = itemsPendingDelete {
                    delete(items)
                }
                itemsPendingDelete = nil
            }
            Button("キャンセル", role: .cancel) {
                itemsPendingDelete = nil
            }
        } message: {
            Text("削除すると元に戻せません。")
        }
    }

    private func categoryHeader(group: (category: PackingCategory, items: [PackingItem])) -> some View {
        let checked = group.items.filter(\.isChecked).count
        return HStack {
            Text(group.category.title)
            Spacer()
            Text("\(checked)/\(group.items.count)")
                .foregroundStyle(checked == group.items.count ? AppTheme.accent : .secondary)
        }
    }

    private func toggle(_ item: PackingItem) {
        item.isChecked.toggle()
        item.updatedAt = .now
        HapticsService.lightImpact()
        try? modelContext.save()
    }

    private func addItem(to trip: Trip) {
        let name = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let item = PackingItem(trip: trip, name: name, category: newItemCategory, orderIndex: trip.packingItems.count)
        trip.packingItems.append(item)
        newItemName = ""
        try? modelContext.save()
    }

    private func applyTemplate(_ template: PackingService.QuickTemplate, to trip: Trip) {
        for (index, entry) in template.items.enumerated() {
            let item = PackingItem(
                trip: trip,
                name: entry.name,
                category: entry.category,
                orderIndex: trip.packingItems.count + index
            )
            trip.packingItems.append(item)
        }
        try? modelContext.save()
    }

    private func delete(_ items: [PackingItem]) {
        for item in items {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        PackingHomeView()
    }
}
