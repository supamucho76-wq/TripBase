import Foundation

enum DocumentStatus {
    case ok
    case expiringSoon
    case expired
}

enum DocumentService {
    /// Passports/visas are conventionally flagged for renewal well before
    /// they expire (many countries require 6 months' validity remaining to
    /// enter), so anything inside that window is worth calling out even
    /// though it isn't expired yet.
    static let expiringSoonWindowDays = 180

    static func status(for document: TripDocument, now: Date = .now, calendar: Calendar = .current) -> DocumentStatus {
        guard let expiryDate = document.expiryDate else { return .ok }
        let daysUntilExpiry = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: expiryDate)
        ).day ?? 0
        if daysUntilExpiry < 0 { return .expired }
        if daysUntilExpiry <= expiringSoonWindowDays { return .expiringSoon }
        return .ok
    }

    static func unconfirmedCount(_ documents: [TripDocument]) -> Int {
        documents.filter { !$0.isConfirmed }.count
    }
}
