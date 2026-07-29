import SwiftData
import SwiftUI

struct TimezoneOverviewView: View {
    @Query(sort: \Trip.createdAt) private var trips: [Trip]

    private var allLegs: [TripLeg] {
        trips.flatMap(\.legs)
    }

    private var relevantLegs: [TripLeg] {
        let current = TripStatusService.currentLeg(in: allLegs)
        let upcoming = TripStatusService.upcomingLegs(in: allLegs, excluding: current)
        return ([current].compactMap { $0 } + upcoming).prefix(5).map { $0 }
    }

    var body: some View {
        Group {
            if relevantLegs.isEmpty {
                ContentUnavailableView(
                    "行程がまだありません",
                    systemImage: "clock",
                    description: Text("出張先を登録すると、時差がここに表示されます。")
                )
            } else {
                List(relevantLegs) { leg in
                    row(for: leg)
                }
            }
        }
        .contentMargins(.bottom, 90, for: .scrollContent)
        .navigationTitle("時差")
    }

    @ViewBuilder
    private func row(for leg: TripLeg) -> some View {
        if let info = CountryInfoStore.lookup(leg.countryCode) {
            let diff = TimezoneService.hourDifference(destinationIdentifier: info.timeZoneIdentifier)
            let currentTime = TimezoneService.currentTime(destinationIdentifier: info.timeZoneIdentifier)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(leg.cityName)（\(leg.countryCode)）")
                    .font(.headline)
                if let currentTime {
                    Text("現地時刻: \(currentTime)")
                }
                if let diff {
                    Text(diff == 0 ? "日本と時差はありません" : "日本より\(diff > 0 ? "\(diff)時間進んでいます" : "\(-diff)時間遅れています")")
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(leg.cityName)（\(leg.countryCode)）")
                    .font(.headline)
                Text("時差データは準備中です")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TimezoneOverviewView()
    }
}
