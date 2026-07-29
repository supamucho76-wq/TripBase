import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var trips: [Trip]
    @State private var isResetConfirmationPresented = false
    @AppStorage(DateFormatPreference.storageKey) private var dateFormatPreferenceRaw: String = DateFormatPreference.gregorian.rawValue

    var body: some View {
        Form {
            Section("日付表示") {
                Picker("形式", selection: $dateFormatPreferenceRaw) {
                    ForEach(DateFormatPreference.allCases) { preference in
                        Text(preference.title).tag(preference.rawValue)
                    }
                }
            }

            Section("データ") {
                Label("旅程データは現在、この端末内に保存されます", systemImage: "iphone")
                Button("すべてのデータを削除", role: .destructive) {
                    isResetConfirmationPresented = true
                }
                .disabled(trips.isEmpty)
            }

            // 将来的に日当タブを追加する場合はここに設定項目を足す。

            Section("このアプリについて") {
                Text("出張族のための旅程管理アプリです。")
                    .font(.footnote)
                LabeledContent("バージョン", value: "0.1.0")
            }
        }
        .navigationTitle("設定")
        .confirmationDialog(
            "すべてのデータを削除しますか?",
            isPresented: $isResetConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive, action: resetAllData)
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("すべての出張・行程が削除され、元に戻せません。")
        }
    }

    private func resetAllData() {
        for trip in trips {
            modelContext.delete(trip)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
