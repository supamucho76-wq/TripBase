import SwiftData
import SwiftUI

struct TripNoteEditorView: View {
    let trip: Trip
    let existingNote: TripNote?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var category: NoteCategory
    @State private var noteBody: String
    @State private var isPinned: Bool
    @State private var errorMessage: String?
    @State private var isDeleteConfirmationPresented = false

    init(trip: Trip, existingNote: TripNote?) {
        self.trip = trip
        self.existingNote = existingNote

        _title = State(initialValue: existingNote?.title ?? "")
        _category = State(initialValue: existingNote?.category ?? .wholeTrip)
        _noteBody = State(initialValue: existingNote?.body ?? "")
        _isPinned = State(initialValue: existingNote?.isPinned ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(NoteCategory.allCases) { category in
                            Label(category.title, systemImage: category.systemImage).tag(category)
                        }
                    }
                    TextField("タイトル（必須）", text: $title)
                    TextField("内容", text: $noteBody, axis: .vertical)
                        .lineLimit(5...10)
                }

                Section {
                    Toggle("ピン留めする", isOn: $isPinned)
                }

                Section {
                    Button(existingNote == nil ? "追加する" : "変更を保存", action: save)
                        .buttonStyle(LargeActionButtonStyle())
                        .listRowInsets(EdgeInsets())
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if existingNote != nil {
                    Section {
                        Button("このメモを削除", role: .destructive) {
                            isDeleteConfirmationPresented = true
                        }
                    }
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(AppTheme.danger) }
                }
            }
            .navigationTitle(existingNote == nil ? "メモを追加" : "メモを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .alert("このメモを削除しますか？", isPresented: $isDeleteConfirmationPresented) {
                Button("削除", role: .destructive, action: deleteNote)
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("削除した内容は元に戻せません。")
            }
        }
    }

    private func save() {
        let note = existingNote ?? TripNote(trip: trip, title: "")
        note.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        note.category = category
        note.body = noteBody.trimmingCharacters(in: .whitespacesAndNewlines)
        note.isPinned = isPinned
        note.updatedAt = .now

        if existingNote == nil {
            trip.notesList.append(note)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteNote() {
        guard let existingNote else { return }
        trip.notesList.removeAll(where: { $0 === existingNote })
        modelContext.delete(existingNote)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    TripNoteEditorView(trip: Trip(name: "Preview"), existingNote: nil)
}
