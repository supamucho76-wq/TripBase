import SwiftData
import SwiftUI

struct TripDocumentListView: View {
    @Bindable var trip: Trip

    @Environment(\.modelContext) private var modelContext
    @State private var isNewDocumentPresented = false
    @State private var documentPendingEdit: TripDocument?
    @State private var documentPendingDelete: TripDocument?

    private var sortedDocuments: [TripDocument] {
        trip.documents.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var groupedDocuments: [(category: DocumentCategory, documents: [TripDocument])] {
        DocumentCategory.allCases.compactMap { category in
            let matching = sortedDocuments.filter { $0.category == category }
            return matching.isEmpty ? nil : (category, matching)
        }
    }

    var body: some View {
        Group {
            if trip.documents.isEmpty {
                ContentUnavailableView(
                    "書類がまだ登録されていません",
                    systemImage: "doc.text",
                    description: Text("航空券・パスポート・ビザ・保険などをまとめて登録できます。")
                )
            } else {
                List {
                    let unconfirmedCount = DocumentService.unconfirmedCount(trip.documents)
                    Section {
                        HStack {
                            Text(unconfirmedCount == 0 ? "すべて確認済みです" : "未確認の書類が\(unconfirmedCount)件あります")
                                .font(.subheadline.bold())
                                .foregroundStyle(unconfirmedCount == 0 ? AppTheme.accent : .primary)
                            Spacer()
                            if unconfirmedCount == 0 {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                    }

                    ForEach(groupedDocuments, id: \.category) { group in
                        Section(group.category.title) {
                            ForEach(group.documents) { document in
                                Button {
                                    documentPendingEdit = document
                                } label: {
                                    documentRow(document)
                                }
                                .buttonStyle(.plain)
                                .swipeActions {
                                    Button("削除", role: .destructive) {
                                        documentPendingDelete = document
                                    }
                                    Button("編集") {
                                        documentPendingEdit = document
                                    }
                                    .tint(AppTheme.accent)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .listSectionSpacing(.compact)
                .contentMargins(.bottom, 90, for: .scrollContent)
            }
        }
        .navigationTitle("書類")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isNewDocumentPresented = true
                } label: {
                    Label("書類を追加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isNewDocumentPresented) {
            TripDocumentEditorView(trip: trip, existingDocument: nil)
        }
        .sheet(item: $documentPendingEdit) { document in
            TripDocumentEditorView(trip: trip, existingDocument: document)
        }
        .alert(
            "この書類を削除しますか？",
            isPresented: Binding(
                get: { documentPendingDelete != nil },
                set: { isPresented in
                    if !isPresented { documentPendingDelete = nil }
                }
            )
        ) {
            Button("削除", role: .destructive) {
                if let document = documentPendingDelete {
                    modelContext.delete(document)
                }
                documentPendingDelete = nil
            }
            Button("キャンセル", role: .cancel) {
                documentPendingDelete = nil
            }
        } message: {
            Text("削除すると元に戻せません。")
        }
    }

    private func documentRow(_ document: TripDocument) -> some View {
        let status = DocumentService.status(for: document)

        return HStack(spacing: 10) {
            Image(systemName: document.isConfirmed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(document.isConfirmed ? AppTheme.accent : .secondary)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(document.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    if document.hasAttachment {
                        Image(systemName: "paperclip")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if !document.referenceNumber.isEmpty {
                    Text(document.referenceNumber)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let expiryDate = document.expiryDate {
                    Text("有効期限: \(AppDateFormatter.date.string(from: expiryDate))")
                        .font(.caption)
                        .foregroundStyle(status == .ok ? .secondary : AppTheme.danger)
                }
            }
            Spacer()
            if status == .expired {
                StatusBadge(title: "期限切れ", color: AppTheme.danger)
            } else if status == .expiringSoon {
                StatusBadge(title: "要確認", color: AppTheme.warning)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        TripDocumentListView(trip: Trip(name: "Preview"))
    }
}
