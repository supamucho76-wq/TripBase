import SwiftData
import SwiftUI

struct TripDocumentEditorView: View {
    let trip: Trip
    let existingDocument: TripDocument?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var category: DocumentCategory
    @State private var referenceNumber: String
    @State private var hasExpiryDate: Bool
    @State private var expiryDate: Date
    @State private var notes: String
    @State private var isConfirmed: Bool
    @State private var errorMessage: String?
    @State private var isDeleteConfirmationPresented = false

    init(trip: Trip, existingDocument: TripDocument?, defaultCategory: DocumentCategory = .other) {
        self.trip = trip
        self.existingDocument = existingDocument

        _name = State(initialValue: existingDocument?.name ?? "")
        _category = State(initialValue: existingDocument?.category ?? defaultCategory)
        _referenceNumber = State(initialValue: existingDocument?.referenceNumber ?? "")
        _hasExpiryDate = State(initialValue: existingDocument?.expiryDate != nil)
        _expiryDate = State(initialValue: existingDocument?.expiryDate ?? .now)
        _notes = State(initialValue: existingDocument?.notes ?? "")
        _isConfirmed = State(initialValue: existingDocument?.isConfirmed ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("種類", selection: $category) {
                        ForEach(DocumentCategory.allCases) { category in
                            Label(category.title, systemImage: category.systemImage).tag(category)
                        }
                    }
                    TextField("名称（必須）", text: $name)
                    TextField("予約番号・書類番号", text: $referenceNumber)
                }

                Section {
                    Toggle("有効期限を設定する", isOn: $hasExpiryDate.animation())
                    if hasExpiryDate {
                        DatePicker("有効期限", selection: $expiryDate, displayedComponents: .date)
                    }
                } footer: {
                    Text("パスポート・ビザは入国に必要な残存期間（多くの国で6か月以上）に注意してください。")
                }

                Section {
                    TextField("メモ", text: $notes, axis: .vertical)
                }

                Section {
                    Toggle("確認済み", isOn: $isConfirmed)
                } footer: {
                    Text("準備・確認が済んだらオンにしてください。")
                }

                Section {
                    Button(existingDocument == nil ? "追加する" : "変更を保存", action: save)
                        .buttonStyle(LargeActionButtonStyle())
                        .listRowInsets(EdgeInsets())
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if existingDocument != nil {
                    Section {
                        Button("この書類を削除", role: .destructive) {
                            isDeleteConfirmationPresented = true
                        }
                    }
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(AppTheme.danger) }
                }
            }
            .navigationTitle(existingDocument == nil ? "書類を追加" : "書類を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .alert("この書類を削除しますか？", isPresented: $isDeleteConfirmationPresented) {
                Button("削除", role: .destructive, action: deleteDocument)
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("削除した内容は元に戻せません。")
            }
        }
    }

    private func save() {
        let document = existingDocument ?? TripDocument(
            trip: trip,
            name: "",
            category: category,
            orderIndex: trip.documents.count
        )
        document.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        document.category = category
        document.referenceNumber = referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        document.expiryDate = hasExpiryDate ? expiryDate : nil
        document.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        document.isConfirmed = isConfirmed
        document.updatedAt = .now

        if existingDocument == nil {
            trip.documents.append(document)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteDocument() {
        guard let existingDocument else { return }
        trip.documents.removeAll(where: { $0 === existingDocument })
        modelContext.delete(existingDocument)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    TripDocumentEditorView(trip: Trip(name: "Preview"), existingDocument: nil)
}
