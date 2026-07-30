import SwiftData
import SwiftUI

struct TripNoteListView: View {
    @Bindable var trip: Trip

    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedCategory: NoteCategory?
    @State private var isNewNotePresented = false
    @State private var notePendingEdit: TripNote?
    @State private var notePendingDelete: TripNote?

    private var filteredNotes: [TripNote] {
        trip.notesList
            .filter { selectedCategory == nil || $0.category == selectedCategory }
            .filter {
                searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || $0.title.localizedCaseInsensitiveContains(searchText)
                    || $0.body.localizedCaseInsensitiveContains(searchText)
            }
            .sorted {
                if $0.isPinned != $1.isPinned { return $0.isPinned }
                return $0.updatedAt > $1.updatedAt
            }
    }

    var body: some View {
        Group {
            if trip.notesList.isEmpty {
                ContentUnavailableView(
                    "メモがまだありません",
                    systemImage: "note.text",
                    description: Text("出張中の気づきや次回への引き継ぎをメモできます。")
                )
            } else {
                List {
                    Section {
                        Picker("カテゴリ", selection: $selectedCategory) {
                            Text("すべて").tag(NoteCategory?.none)
                            ForEach(NoteCategory.allCases) { category in
                                Text(category.title).tag(NoteCategory?.some(category))
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    ForEach(filteredNotes) { note in
                        Button {
                            notePendingEdit = note
                        } label: {
                            noteRow(note)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("削除", role: .destructive) {
                                notePendingDelete = note
                            }
                            Button(note.isPinned ? "ピン解除" : "ピン留め") {
                                togglePin(note)
                            }
                            .tint(AppTheme.warning)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .contentMargins(.bottom, 90, for: .scrollContent)
                .searchable(text: $searchText, prompt: "メモを検索")
            }
        }
        .navigationTitle("メモ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isNewNotePresented = true
                } label: {
                    Label("メモを追加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isNewNotePresented) {
            TripNoteEditorView(trip: trip, existingNote: nil)
        }
        .sheet(item: $notePendingEdit) { note in
            TripNoteEditorView(trip: trip, existingNote: note)
        }
        .alert(
            "このメモを削除しますか？",
            isPresented: Binding(
                get: { notePendingDelete != nil },
                set: { isPresented in
                    if !isPresented { notePendingDelete = nil }
                }
            )
        ) {
            Button("削除", role: .destructive) {
                if let note = notePendingDelete {
                    modelContext.delete(note)
                }
                notePendingDelete = nil
            }
            Button("キャンセル", role: .cancel) {
                notePendingDelete = nil
            }
        } message: {
            Text("削除すると元に戻せません。")
        }
    }

    private func noteRow(_ note: TripNote) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.warning)
                }
                Text(note.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Spacer()
                Text(note.category.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if !note.body.isEmpty {
                Text(note.body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }

    private func togglePin(_ note: TripNote) {
        note.isPinned.toggle()
        note.updatedAt = .now
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        TripNoteListView(trip: Trip(name: "Preview"))
    }
}
