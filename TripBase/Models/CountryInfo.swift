import Foundation

struct CountryInfo: Codable, Identifiable {
    var id: String { countryCode }

    let countryCode: String
    let nameJa: String
    let nameEn: String
    let timeZoneIdentifier: String
    let currencyCode: String
    let plugTypes: [String]
    let voltage: Int
    let frequencyHz: Int
    let tippingNote: String
    let packingAddenda: [String]
    let mofaSafetyURL: String?
    let embassy: EmbassyContact?

    struct EmbassyContact: Codable {
        let name: String
        let address: String
        let phone: String
        let website: String?
    }
}
