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
                HStack(spacing: 6) {
                    Text(WeatherCodeDescription.symbol(for: forecast.daily.weatherCode[firstIndex]))
                    Text("\(Int(forecast.daily.temperature2mMin[firstIndex].rounded()))° / \(Int(forecast.daily.temperature2mMax[firstIndex].rounded()))°")
                        .font(.title3.bold())
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
        .task(id: leg.cityName) {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        let cityName = leg.cityName
        let result = await APICache.fetch(key: "weather-\(cityName)") {
            guard let forecast = try await WeatherAPIClient.fetchForecast(cityName: cityName) else {
                throw URLError(.cannotFindHost)
            }
            return forecast
        }
        if let value = result.value {
            forecast = value
            isStale = result.isStale
        } else {
            errorMessage = "天気を取得できませんでした"
        }
        isLoading = false
    }
}
