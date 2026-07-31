import SwiftData
import SwiftUI

struct TripTemplateListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Trip> { $0.isTemplate }, sort: \Trip.createdAt) private var templates: [Trip]
    @State private var templatePendingDelete: Trip?
    @State private var newlyCreatedTrip: Trip?

    var body: some View {
        Group {
            if templates.isEmpty {
                ContentUnavailableView(
                    "テンプレートがまだありません",
                    systemImage: "doc.on.doc",
                    description: Text("出張詳細の「…」メニューから「テンプレートとして保存」すると、ここに追加されます。")
                )
            } else {
                List {
                    ForEach(templates) { template in
                        HStack {
                            NavigationLink {
                                TripDetailView(trip: template)
                            } label: {
                                templateRow(template)
                            }
                            Spacer()
                            Button("使う") {
                                createTrip(from: template)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.accent)
                        }
                        .swipeActions {
                            Button("削除", role: .destructive) {
                                templatePendingDelete = template
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .contentMargins(.bottom, 90, for: .scrollContent)
            }
        }
        .navigationTitle("テンプレート管理")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $newlyCreatedTrip) { trip in
            NavigationStack {
                TripDetailView(trip: trip)
            }
        }
        .alert(
            "このテンプレートを削除しますか？",
            isPresented: Binding(
                get: { templatePendingDelete != nil },
                set: { isPresented in
                    if !isPresented { templatePendingDelete = nil }
                }
            )
        ) {
            Button("削除", role: .destructive) {
                if let template = templatePendingDelete {
                    modelContext.delete(template)
                }
                templatePendingDelete = nil
            }
            Button("キャンセル", role: .cancel) {
                templatePendingDelete = nil
            }
        } message: {
            Text("削除すると元に戻せません。")
        }
    }

    private func templateRow(_ template: Trip) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name)
                .font(.headline)
            if !template.purpose.isEmpty {
                Text(template.purpose)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("行程\(template.legs.count)件・持ち物\(template.packingItems.count)件")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func createTrip(from template: Trip) {
        let newTrip = TripDuplicationService.duplicate(source: template, asTemplate: false, in: modelContext)
        try? modelContext.save()
        HapticsService.success()
        newlyCreatedTrip = newTrip
    }
}

#Preview {
    NavigationStack {
        TripTemplateListView()
    }
}
