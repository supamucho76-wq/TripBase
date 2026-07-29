import SwiftData
import SwiftUI

struct TripEditorView: View {
    let existingTrip: Trip?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var purpose: String
    @State private var notes: String
    @State private var errorMessage: String?

    init(existingTrip: Trip?) {
        self.existingTrip = existingTrip
        _name = State(initialValue: existingTrip?.name ?? "")
        _purpose = State(initialValue: existingTrip?.purpose ?? "")
        _notes = State(initialValue: existingTrip?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("出張名（必須）", text: $name)
                        .accessibilityIdentifier("trip.name")
                    TextField("出張目的", text: $purpose)
                    TextField("メモ", text: $notes, axis: .vertical)
                }

                Section {
                    Button(existingTrip == nil ? "追加する" : "変更を保存", action: save)
                        .accessibilityIdentifier("trip.save")
                        .buttonStyle(LargeActionButtonStyle())
                        .listRowInsets(EdgeInsets())
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(AppTheme.danger) }
                }
            }
            .navigationTitle(existingTrip == nil ? "出張を追加" : "出張を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let trip = existingTrip ?? Trip(name: "")
        trip.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        trip.purpose = purpose.trimmingCharacters(in: .whitespacesAndNewlines)
        trip.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        trip.updatedAt = .now

        if existingTrip == nil {
            modelContext.insert(trip)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
