import SwiftData
import SwiftUI

struct WeatherView: View {
    @Query(sort: \Trip.createdAt) private var trips: [Trip]

    @State private var forecastsByLegID: [UUID: WeatherForecast] = [:]
    @State private var staleLegIDs: Set<UUID> = []
    @State private var errorsByLegID: [UUID: String] = [:]
    @State private var loadingLegIDs: Set<UUID> = []
    @State private var fetchedAtByLegID: [UUID: Date] = [:]

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
        .contentMargins(.bottom, 90, for: .scrollContent)
        .background(AppTheme.background)
        .navigationTitle("天気")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await loadForecasts(force: true) }
                } label: {
                    Label("更新", systemImage: "arrow.clockwise")
                }
                .accessibilityLabel("天気を更新する")
            }
        }
        .task(id: relevantLegs.map(\.id)) {
            await loadForecasts()
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
                if let current = forecast.current {
                    HStack(spacing: 8) {
                        Text(WeatherCodeDescription.symbol(for: current.weatherCode))
                            .font(.title)
                        Text("\(Int(current.temperature2m.rounded()))°")
                            .font(.largeTitle.bold())
                        Text("現在")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Divider()
                forecastRows(forecast)
                if staleLegIDs.contains(leg.id) {
                    Text("オフライン — 前回取得時点の情報")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if let fetchedAt = fetchedAtByLegID[leg.id] {
                    Text("最終更新: \(fetchedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else if let errorMessage = errorsByLegID[leg.id] {
                VStack(alignment: .leading, spacing: 8) {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button {
                        Task { await loadForecast(for: leg, force: true) }
                    } label: {
                        Label("再試行", systemImage: "arrow.clockwise")
                            .font(.footnote.bold())
                    }
                }
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

    private func loadForecasts(force: Bool = false) async {
        for leg in relevantLegs where force || forecastsByLegID[leg.id] == nil {
            await loadForecast(for: leg, force: force)
        }
    }

    private func loadForecast(for leg: TripLeg, force: Bool) async {
        let legID = leg.id
        let queryName = leg.weatherQueryName
        loadingLegIDs.insert(legID)
        errorsByLegID[legID] = nil
        staleLegIDs.remove(legID)

        let result = await APICache.fetch(key: "weather-\(queryName)") {
            guard let forecast = try await WeatherAPIClient.fetchForecast(cityName: queryName) else {
                throw URLError(.cannotFindHost)
            }
            return forecast
        }
        if let forecast = result.value {
            forecastsByLegID[legID] = forecast
            if let fetchedAt = result.fetchedAt {
                fetchedAtByLegID[legID] = fetchedAt
            }
            if result.isStale {
                staleLegIDs.insert(legID)
            }
        } else if (try? await WeatherAPIClient.geocode(cityName: queryName)) == nil {
            errorsByLegID[legID] = "「\(queryName)」の地名が見つかりませんでした。行程の編集画面で「天気検索用の都市名」にローマ字表記（例: Taichung）を登録すると見つかりやすくなります。"
        } else {
            errorsByLegID[legID] = "オフラインか、天気を取得できませんでした。"
        }
        loadingLegIDs.remove(legID)
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
    NavigationStack {
        WeatherView()
    }
}
