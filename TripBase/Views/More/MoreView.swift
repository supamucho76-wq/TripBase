import SwiftData
import SwiftUI

struct MoreView: View {
    @Query(sort: \Trip.createdAt) private var trips: [Trip]

    private var allLegs: [TripLeg] {
        trips.flatMap(\.legs)
    }

    private var currentOrNextLeg: TripLeg? {
        TripStatusService.currentLeg(in: allLegs) ?? TripStatusService.nextLeg(in: allLegs)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("トリップ情報") {
                    NavigationLink("天気") { WeatherView() }
                    NavigationLink("為替") { ForexView() }
                    NavigationLink("時差") { TimezoneOverviewView() }
                    NavigationLink("現地情報") {
                        if let leg = currentOrNextLeg {
                            DestinationInfoView(leg: leg)
                        } else {
                            ContentUnavailableView(
                                "行程がまだありません",
                                systemImage: "mappin.and.ellipse",
                                description: Text("出張先を登録すると、現地情報が使えるようになります。")
                            )
                        }
                    }
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
            }
            .navigationTitle("その他")
        }
    }
}

#Preview {
    MoreView()
}
