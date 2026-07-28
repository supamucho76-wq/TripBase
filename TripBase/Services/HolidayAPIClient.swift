import Foundation

struct PublicHoliday: Codable, Identifiable, Equatable {
    let date: String
    let localName: String
    let name: String

    var id: String { date + name }
}

enum HolidayAPIClient {
    static func fetchHolidays(countryCode: String, year: Int) async throws -> [PublicHoliday] {
        guard let url = URL(string: "https://date.nager.at/api/v3/PublicHolidays/\(year)/\(countryCode)") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if httpResponse.statusCode == 204 {
            return []
        }
        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode([PublicHoliday].self, from: data)
    }
}
