import SwiftUI

struct PhrasebookView: View {
    @State private var selectedCategory: PhraseCategory?
    @State private var favoritesVersion = UUID()

    private var favoritePhrases: [Phrase] {
        let favoriteIDs = FavoritePhraseStore.favoriteIDs
        return PhraseStore.all.filter { favoriteIDs.contains($0.id) }
    }

    var body: some View {
        List {
            if !favoritePhrases.isEmpty {
                Section("お気に入り") {
                    ForEach(favoritePhrases) { phrase in
                        NavigationLink {
                            PhraseDetailView(phrase: phrase) {
                                favoritesVersion = UUID()
                            }
                        } label: {
                            phraseRow(phrase)
                        }
                    }
                }
            }

            Section {
                ForEach(PhraseCategory.allCases) { category in
                    NavigationLink {
                        PhraseListView(category: category) {
                            favoritesVersion = UUID()
                        }
                    } label: {
                        Label(category.title, systemImage: category.systemImage)
                    }
                }
            } header: {
                Text("カテゴリ")
            } footer: {
                Text("日本語から英語への定型文集です。オフラインでも使えます。")
            }
        }
        .id(favoritesVersion)
        .listStyle(.insetGrouped)
        .contentMargins(.bottom, 90, for: .scrollContent)
        .navigationTitle("翻訳")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func phraseRow(_ phrase: Phrase) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(phrase.japanese)
                .font(.subheadline.bold())
            Text(phrase.english)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PhraseListView: View {
    let category: PhraseCategory
    let onFavoriteChanged: () -> Void

    var body: some View {
        List(PhraseStore.phrases(in: category)) { phrase in
            NavigationLink {
                PhraseDetailView(phrase: phrase, onFavoriteChanged: onFavoriteChanged)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(phrase.japanese)
                        .font(.subheadline.bold())
                    Text(phrase.english)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.bottom, 90, for: .scrollContent)
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PhraseDetailView: View {
    let phrase: Phrase
    let onFavoriteChanged: () -> Void

    @State private var isFavorite: Bool

    init(phrase: Phrase, onFavoriteChanged: @escaping () -> Void) {
        self.phrase = phrase
        self.onFavoriteChanged = onFavoriteChanged
        _isFavorite = State(initialValue: FavoritePhraseStore.isFavorite(phrase.id))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("日本語")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(phrase.japanese)
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    Text("English")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(phrase.english)
                        .font(.system(size: 32, weight: .bold))
                    CopyButton(text: phrase.english, label: "コピー", systemImage: "doc.on.doc")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle(phrase.category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    FavoritePhraseStore.toggle(phrase.id)
                    isFavorite.toggle()
                    onFavoriteChanged()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? AppTheme.warning : .secondary)
                }
                .accessibilityLabel(isFavorite ? "お気に入りから削除" : "お気に入りに追加")
            }
        }
    }
}

#Preview {
    NavigationStack {
        PhrasebookView()
    }
}
