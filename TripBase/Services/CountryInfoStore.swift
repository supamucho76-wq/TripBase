import Foundation

@MainActor
enum CountryInfoStore {
    static let all: [String: CountryInfo] = {
        guard
            let url = Bundle.main.url(forResource: "CountryInfo", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let list = try? JSONDecoder().decode([CountryInfo].self, from: data)
        else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: list.map { ($0.countryCode, $0) })
    }()

    static var allSorted: [CountryInfo] {
        all.values.sorted { $0.nameJa.localizedStandardCompare($1.nameJa) == .orderedAscending }
    }

    static func lookup(_ countryCode: String) -> CountryInfo? {
        all[countryCode.uppercased()]
    }

    static func displayName(for countryCode: String) -> String {
        if let info = lookup(countryCode) {
            return info.nameJa
        }
        return Locale.current.localizedString(forRegionCode: countryCode) ?? countryCode
    }
}
