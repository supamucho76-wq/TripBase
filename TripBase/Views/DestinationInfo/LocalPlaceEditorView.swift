import SwiftData
import SwiftUI

struct LocalPlaceEditorView: View {
    let leg: TripLeg

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: LocalPlaceCategory = .other
    @State private var address = ""
    @State private var phone = ""
    @State private var notes = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("名称（必須）", text: $name)
                    Picker("カテゴリ", selection: $category) {
                        ForEach(LocalPlaceCategory.allCases) { category in
                            Label(category.title, systemImage: category.systemImage).tag(category)
                        }
                    }
                    TextField("住所", text: $address, axis: .vertical)
                    TextField("電話番号", text: $phone)
                    TextField("メモ", text: $notes, axis: .vertical)
                }

                Section {
                    Button("追加する", action: save)
                        .buttonStyle(LargeActionButtonStyle())
                        .listRowInsets(EdgeInsets())
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(AppTheme.danger) }
                }
            }
            .navigationTitle("場所を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let place = LocalPlace(
            tripLeg: leg,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            orderIndex: leg.localPlaces.count
        )
        leg.localPlaces.append(place)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
