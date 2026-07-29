import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("トリップ情報") {
                    NavigationLink("天気") { WeatherView() }
                    NavigationLink("為替") { ForexView() }
                    NavigationLink("時差") { TimezoneOverviewView() }
                    NavigationLink("翻訳") {
                        ContentUnavailableView(
                            "翻訳機能は準備中です",
                            systemImage: "text.bubble",
                            description: Text("出張先でよく使う定型文を保存できるようになります。")
                        )
                        .navigationTitle("翻訳")
                    }
                }

                Section("管理") {
                    NavigationLink("出張履歴") {
                        TripListView(initialStatusFilter: .completed)
                    }
                }

                Section {
                    NavigationLink("設定") { SettingsView() }
                }
            }
            .navigationTitle("その他")
        }
    }
}

#Preview {
    MoreView()
}
