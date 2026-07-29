import SwiftData
import SwiftUI

struct PackingHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @State private var selectedTripID: UUID?
    @State private var newItemName = ""
    @State private var newItemCategory: PackingCategory = .misc

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
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(trip.name)
                        .font(.headline)
                    ProgressView(value: PackingService.percentComplete(trip.packingItems))
                        .tint(AppTheme.accent)
                    Text("持ち物 \(trip.packingItems.filter(\.isChecked).count)/\(trip.packingItems.count)完了")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            if trip.packingItems.isEmpty {
                Section("テンプレートから追加") {
                    ForEach(PackingService.QuickTemplate.allCases) { template in
                        Button(template.title) {
                            applyTemplate(template, to: trip)
                        }
                    }
                }
            }

            ForEach(groupedItems(for: trip), id: \.category) { group in
                Section(group.category.title) {
                    ForEach(group.items) { item in
                        Button {
                            toggle(item)
                        } label: {
                            HStack {
                                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isChecked ? AppTheme.accent : .secondary)
                                Text(item.name)
                                    .foregroundStyle(.primary)
                                    .strikethrough(item.isChecked)
                                Spacer()
                            }
                        }
                    }
                    .onDelete { offsets in
                        delete(offsets, in: group.items)
                    }
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
                    }
                    .disabled(newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func toggle(_ item: PackingItem) {
        item.isChecked.toggle()
        item.updatedAt = .now
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

    private func delete(_ offsets: IndexSet, in items: [PackingItem]) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        PackingHomeView()
    }
}
