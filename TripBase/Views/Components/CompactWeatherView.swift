import SwiftUI

struct CompactWeatherView: View {
    let leg: TripLeg

    @State private var forecast: WeatherForecast?
    @State private var isStale = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("現地の天気", systemImage: "cloud.sun")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            if let forecast, let firstIndex = forecast.daily.time.indices.first {
                if let current = forecast.current {
                    HStack(spacing: 6) {
                        Text(WeatherCodeDescription.symbol(for: current.weatherCode))
                        Text("\(Int(current.temperature2m.rounded()))°")
                            .font(.title3.bold())
                        Text("(\(Int(forecast.daily.temperature2mMin[firstIndex].rounded()))° / \(Int(forecast.daily.temperature2mMax[firstIndex].rounded()))°)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack(spacing: 6) {
                        Text(WeatherCodeDescription.symbol(for: forecast.daily.weatherCode[firstIndex]))
                        Text("\(Int(forecast.daily.temperature2mMin[firstIndex].rounded()))° / \(Int(forecast.daily.temperature2mMax[firstIndex].rounded()))°")
                            .font(.title3.bold())
                    }
                }
                if isStale {
                    Text("オフライン — 前回取得時点")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else if let errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: leg.weatherQueryName) {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        let queryName = leg.weatherQueryName
        let result = await APICache.fetch(key: "weather-\(queryName)") {
            guard let forecast = try await WeatherAPIClient.fetchForecast(cityName: queryName) else {
                throw URLError(.cannotFindHost)
            }
            return forecast
        }
        if let value = result.value {
            forecast = value
            isStale = result.isStale
        } else {
            errorMessage = "「\(queryName)」の天気を取得できませんでした"
        }
        isLoading = false
    }
}
