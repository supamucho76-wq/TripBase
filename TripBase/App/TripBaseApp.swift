import SwiftData
import SwiftUI

enum AppRuntime {
    static let isUITesting = CommandLine.arguments.contains("--ui-testing")
}

@main
@MainActor
struct TripBaseApp: App {
    private let container: ModelContainer?
    private let initializationError: String?

    init() {
        let schema = Schema([
            Trip.self,
            TripLeg.self,
            PackingItem.self,
            LocalPlace.self,
            TripDocument.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: AppRuntime.isUITesting
        )

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
            initializationError = nil
        } catch {
            container = nil
            initializationError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView()
                    .modelContainer(container)
            } else {
                DataStoreErrorView(message: initializationError ?? "不明なエラー")
            }
        }
    }
}

private struct DataStoreErrorView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("旅程データを開けません", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text("アプリを終了して端末を再起動してから、もう一度お試しください。改善しない場合は、アプリを削除せずサポートへ連絡してください。\n\n\(message)")
        }
    }
}
