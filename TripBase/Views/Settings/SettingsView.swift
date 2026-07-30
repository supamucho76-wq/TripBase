import SwiftData
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var trips: [Trip]
    @State private var isResetConfirmationPresented = false
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @AppStorage(DateFormatPreference.storageKey) private var dateFormatPreferenceRaw: String = DateFormatPreference.gregorian.rawValue
    @AppStorage(AppearancePreference.storageKey) private var appearancePreferenceRaw: String = AppearancePreference.system.rawValue
    @AppStorage(NotificationScheduler.enabledKey) private var remindersEnabled = false

    var body: some View {
        Form {
            Section("外観") {
                Picker("テーマ", selection: $appearancePreferenceRaw) {
                    ForEach(AppearancePreference.allCases) { preference in
                        Text(preference.title).tag(preference.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Toggle("出発前リマインダー", isOn: $remindersEnabled)
                    .onChange(of: remindersEnabled) { _, isEnabled in
                        if isEnabled {
                            Task {
                                _ = await NotificationScheduler.requestAuthorizationIfNeeded()
                                authorizationStatus = await NotificationScheduler.authorizationStatus()
                            }
                        }
                    }
                if remindersEnabled && authorizationStatus == .denied {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("設定アプリで通知を許可する", systemImage: "gear")
                    }
                }
            } header: {
                Text("通知")
            } footer: {
                Text("出発7日前・3日前・前日・当日に、持ち物や書類の準備が未完了の場合だけ通知します。")
            }

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
        .contentMargins(.bottom, 90, for: .scrollContent)
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
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
        .task {
            authorizationStatus = await NotificationScheduler.authorizationStatus()
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
