import Foundation

private struct ForexResponse: Codable {
    let amount: Double
    let base: String
    let date: String
    let rates: [String: Double]
}

struct ForexRate: Codable, Equatable, Sendable {
    let rate: Double
    let asOfDate: String
}

enum ForexAPIClient {
    static func fetchRate(from base: String = "JPY", to target: String) async throws -> ForexRate {
        guard target != base else { return ForexRate(rate: 1, asOfDate: "") }
        guard var components = URLComponents(string: "https://api.frankfurter.app/latest") else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "from", value: base),
            URLQueryItem(name: "to", value: target)
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ForexResponse.self, from: data)
        guard let rate = response.rates[target] else {
            throw URLError(.cannotParseResponse)
        }
        return ForexRate(rate: rate, asOfDate: response.date)
    }
}
