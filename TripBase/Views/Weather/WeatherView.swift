import SwiftData
import SwiftUI

struct WeatherView: View {
    @Query(sort: \Trip.createdAt) private var trips: [Trip]

    @State private var forecastsByLegID: [UUID: WeatherForecast] = [:]
    @State private var staleLegIDs: Set<UUID> = []
    @State private var errorsByLegID: [UUID: String] = [:]
    @State private var loadingLegIDs: Set<UUID> = []

    private var allLegs: [TripLeg] {
        trips.flatMap(\.legs)
    }

    private var relevantLegs: [TripLeg] {
        let current = TripStatusService.currentLeg(in: allLegs)
        let upcoming = TripStatusService.upcomingLegs(in: allLegs, excluding: current)
        return ([current].compactMap { $0 } + upcoming).prefix(5).map { $0 }
    }

    var body: some View {
        NavigationStack {
            Group {
                if relevantLegs.isEmpty {
                    ContentUnavailableView(
                        "行程がまだありません",
                        systemImage: "cloud.sun",
                        description: Text("出張先を登録すると、天気がここに表示されます。")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(relevantLegs) { leg in
                                weatherCard(for: leg)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(AppTheme.background)
            .navigationTitle("天気")
            .task(id: relevantLegs.map(\.id)) {
                await loadForecasts()
            }
        }
    }

    private func weatherCard(for leg: TripLeg) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(leg.cityName)（\(leg.countryCode)）")
                    .font(.headline)
                Spacer()
                if loadingLegIDs.contains(leg.id) {
                    ProgressView()
                }
            }
            if let forecast = forecastsByLegID[leg.id] {
                forecastRows(forecast)
                if staleLegIDs.contains(leg.id) {
                    Text("オフライン — 前回取得時点の情報")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else if let errorMessage = errorsByLegID[leg.id] {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func forecastRows(_ forecast: WeatherForecast) -> some View {
        ForEach(Array(forecast.daily.time.enumerated()), id: \.offset) { index, dateString in
            HStack {
                Text(dateString)
                    .font(.subheadline)
                Spacer()
                Text(WeatherCodeDescription.symbol(for: forecast.daily.weatherCode[index]))
                Text("\(Int(forecast.daily.temperature2mMin[index].rounded()))° / \(Int(forecast.daily.temperature2mMax[index].rounded()))°")
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)
        }
    }

    private func loadForecasts() async {
        for leg in relevantLegs where forecastsByLegID[leg.id] == nil {
            loadingLegIDs.insert(leg.id)
            let result = await APICache.fetch(key: "weather-\(leg.cityName)") {
                guard let forecast = try await WeatherAPIClient.fetchForecast(cityName: leg.cityName) else {
                    throw URLError(.cannotFindHost)
                }
                return forecast
            }
            if let forecast = result.value {
                forecastsByLegID[leg.id] = forecast
                if result.isStale {
                    staleLegIDs.insert(leg.id)
                }
            } else {
                errorsByLegID[leg.id] = "オフラインか、天気を取得できませんでした。"
            }
            loadingLegIDs.remove(leg.id)
        }
    }
}

enum WeatherCodeDescription {
    static func symbol(for code: Int) -> String {
        switch code {
        case 0: "☀️"
        case 1, 2, 3: "⛅️"
        case 45, 48: "🌫️"
        case 51, 53, 55, 56, 57: "🌦️"
        case 61, 63, 65, 66, 67: "🌧️"
        case 71, 73, 75, 77: "🌨️"
        case 80, 81, 82: "🌦️"
        case 85, 86: "🌨️"
        case 95, 96, 99: "⛈️"
        default: "🌡️"
        }
    }
}

#Preview {
    WeatherView()
}
