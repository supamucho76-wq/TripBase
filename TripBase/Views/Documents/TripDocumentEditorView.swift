import PhotosUI
import QuickLook
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

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

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isFileImporterPresented = false
    @State private var pendingAttachment: PendingAttachment?
    @State private var shouldRemoveExistingAttachment = false
    @State private var previewURL: URL?
    @State private var attachmentErrorMessage: String?

    private struct PendingAttachment {
        let data: Data
        let fileExtension: String
        let originalFileName: String
    }

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

    private var hasSavedAttachment: Bool {
        existingDocument?.hasAttachment == true && !shouldRemoveExistingAttachment
    }

    private var hasAnyAttachment: Bool {
        pendingAttachment != nil || hasSavedAttachment
    }

    private var attachmentDisplayName: String {
        if let pendingAttachment {
            return pendingAttachment.originalFileName
        }
        return existingDocument?.attachmentOriginalFileName ?? ""
    }

    private var pendingThumbnail: UIImage? {
        guard let pendingAttachment, pendingAttachment.fileExtension.lowercased() != "pdf" else { return nil }
        return UIImage(data: pendingAttachment.data)
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
                    attachmentContent
                } header: {
                    Text("画像・PDF")
                } footer: {
                    if let attachmentErrorMessage {
                        Text(attachmentErrorMessage)
                            .foregroundStyle(AppTheme.danger)
                    } else {
                        Text("航空券・パスポートなどの画像やPDFを添付できます。")
                    }
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
            .onChange(of: photoPickerItem) { _, newValue in
                guard let newValue else { return }
                Task { await loadPhoto(newValue) }
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .quickLookPreview($previewURL)
        }
    }

    @ViewBuilder
    private var attachmentContent: some View {
        if pendingAttachment != nil {
            // Not saved yet - deliberately no modal preview here. Presenting
            // QuickLook on top of this still-unsaved sheet risks a dismiss
            // gesture cascading and closing the edit sheet itself, silently
            // discarding the pending selection. An inline thumbnail (or an
            // icon for PDFs, previewable only after saving) avoids that.
            HStack {
                if let pendingThumbnail {
                    Image(uiImage: pendingThumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                } else {
                    Image(systemName: "doc.richtext")
                        .foregroundStyle(AppTheme.accent)
                }
                Text(attachmentDisplayName)
                    .lineLimit(1)
                Spacer()
                Button(role: .destructive) {
                    removeAttachment()
                } label: {
                    Image(systemName: "trash")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("添付を削除")
            }
        } else if hasSavedAttachment {
            HStack {
                Image(systemName: "paperclip")
                    .foregroundStyle(AppTheme.accent)
                Text(attachmentDisplayName)
                    .lineLimit(1)
                Spacer()
                Button("表示") {
                    showPreview()
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.accent)
                Button(role: .destructive) {
                    removeAttachment()
                } label: {
                    Image(systemName: "trash")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("添付を削除")
            }
        } else {
            HStack(spacing: 16) {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Label("写真", systemImage: "photo")
                }
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("ファイル（PDF等）", systemImage: "doc.badge.plus")
                }
            }
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        attachmentErrorMessage = nil
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                attachmentErrorMessage = "写真を読み込めませんでした。"
                return
            }
            pendingAttachment = PendingAttachment(data: data, fileExtension: "jpg", originalFileName: "写真.jpg")
            shouldRemoveExistingAttachment = false
        } catch {
            attachmentErrorMessage = "写真を読み込めませんでした。"
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        attachmentErrorMessage = nil
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                let fileExtension = url.pathExtension.isEmpty ? "pdf" : url.pathExtension
                pendingAttachment = PendingAttachment(
                    data: data,
                    fileExtension: fileExtension,
                    originalFileName: url.lastPathComponent
                )
                shouldRemoveExistingAttachment = false
            } catch {
                attachmentErrorMessage = "ファイルを読み込めませんでした。"
            }
        case .failure:
            attachmentErrorMessage = "ファイルを読み込めませんでした。"
        }
    }

    private func removeAttachment() {
        pendingAttachment = nil
        photoPickerItem = nil
        shouldRemoveExistingAttachment = true
    }

    private func showPreview() {
        // Only reachable for an already-saved attachment (see
        // attachmentContent) - safe to present a modal here since there's no
        // unsaved pending state that a stray dismiss gesture could discard.
        if let fileName = existingDocument?.attachmentFileName {
            previewURL = TripDocumentStorage.url(for: fileName)
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

        if let pendingAttachment {
            if let oldFileName = document.attachmentFileName {
                TripDocumentStorage.delete(oldFileName)
            }
            do {
                let storedFileName = try TripDocumentStorage.store(
                    data: pendingAttachment.data,
                    fileExtension: pendingAttachment.fileExtension
                )
                document.attachmentFileName = storedFileName
                document.attachmentOriginalFileName = pendingAttachment.originalFileName
            } catch {
                errorMessage = "添付の保存に失敗しました。"
                return
            }
        } else if shouldRemoveExistingAttachment, let oldFileName = document.attachmentFileName {
            TripDocumentStorage.delete(oldFileName)
            document.attachmentFileName = nil
            document.attachmentOriginalFileName = ""
        }

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
        if let fileName = existingDocument.attachmentFileName {
            TripDocumentStorage.delete(fileName)
        }
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
