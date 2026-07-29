import Foundation

struct WeatherForecast: Codable, Equatable {
    let current: CurrentWeather?
    let daily: DailyWeather

    struct CurrentWeather: Codable, Equatable {
        let time: String
        let temperature2m: Double
        let weatherCode: Int

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
        }
    }

    struct DailyWeather: Codable, Equatable {
        let time: [String]
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]
        let weatherCode: [Int]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
            case weatherCode = "weather_code"
        }
    }
}

private struct GeocodeResponse: Codable {
    struct Result: Codable {
        let latitude: Double
        let longitude: Double
    }
    let results: [Result]?
}

enum WeatherAPIClient {
    static func geocode(cityName: String) async throws -> (latitude: Double, longitude: Double)? {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: cityName),
            URLQueryItem(name: "count", value: "1"),
            URLQueryItem(name: "language", value: "ja")
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GeocodeResponse.self, from: data)
        guard let result = response.results?.first else { return nil }
        return (result.latitude, result.longitude)
    }

    static func fetchForecast(latitude: Double, longitude: Double) async throws -> WeatherForecast {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(latitude)"),
            URLQueryItem(name: "longitude", value: "\(longitude)"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,weather_code"),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "5")
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(WeatherForecast.self, from: data)
    }

    static func fetchForecast(cityName: String) async throws -> WeatherForecast? {
        guard let coordinate = try await geocode(cityName: cityName) else { return nil }
        return try await fetchForecast(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
