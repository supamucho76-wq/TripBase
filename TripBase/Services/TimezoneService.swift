import Foundation

enum TimezoneService {
    static let homeIdentifier = "Asia/Tokyo"

    static func hourDifference(destinationIdentifier: String, from baseIdentifier: String = homeIdentifier, at date: Date = .now) -> Int? {
        guard
            let destination = TimeZone(identifier: destinationIdentifier),
            let base = TimeZone(identifier: baseIdentifier)
        else {
            return nil
        }
        let diffSeconds = destination.secondsFromGMT(for: date) - base.secondsFromGMT(for: date)
        return diffSeconds / 3600
    }

    static func currentTime(destinationIdentifier: String, at date: Date = .now) -> String? {
        guard let destination = TimeZone(identifier: destinationIdentifier) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = destination
        return formatter.string(from: date)
    }
}
