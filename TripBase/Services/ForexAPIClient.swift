import Foundation

private struct ExchangeRateResponse: Codable {
    let result: String
    let baseCode: String
    let timeLastUpdateUtc: String
    let rates: [String: Double]

    enum CodingKeys: String, CodingKey {
        case result
        case baseCode = "base_code"
        case timeLastUpdateUtc = "time_last_update_utc"
        case rates
    }
}

struct ForexRate: Codable, Equatable, Sendable {
    let rate: Double
    let asOfDate: String
}

enum ForexAPIClient {
    static func fetchRate(from base: String = "JPY", to target: String) async throws -> ForexRate {
        guard target != base else { return ForexRate(rate: 1, asOfDate: "") }
        guard let url = URL(string: "https://open.er-api.com/v6/latest/\(base)") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        guard response.result == "success", let rate = response.rates[target] else {
            throw URLError(.cannotParseResponse)
        }
        return ForexRate(rate: rate, asOfDate: formattedDate(from: response.timeLastUpdateUtc))
    }

    private static func formattedDate(from utcString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        inputFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        guard let date = inputFormatter.date(from: utcString) else { return utcString }

        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "ja_JP")
        outputFormatter.dateFormat = "M月d日"
        return outputFormatter.string(from: date)
    }
}
