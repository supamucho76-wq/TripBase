import SwiftUI

struct CompactTimezoneView: View {
    let leg: TripLeg

    var body: some View {
        if let info = CountryInfoStore.lookup(leg.countryCode) {
            let diff = TimezoneService.hourDifference(destinationIdentifier: info.timeZoneIdentifier)
            let currentTime = TimezoneService.currentTime(destinationIdentifier: info.timeZoneIdentifier)
            VStack(alignment: .leading, spacing: 4) {
                Label("現地時刻", systemImage: "clock")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                if let currentTime {
                    Text(currentTime)
                        .font(.title3.bold())
                }
                if let diff {
                    Text(diff == 0 ? "日本と時差はありません" : "日本より\(diff > 0 ? "\(diff)時間進んでいます" : "\(-diff)時間遅れています")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
