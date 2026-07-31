import Foundation
import SwiftData

enum TripType {
    case domestic
    case international
}

@Model
final class Trip {
    var id: UUID
    var name: String
    var purpose: String = ""
    var baseCurrencyCode: String = "JPY"
    var isTemplate: Bool = false
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TripLeg.trip)
    var legs: [TripLeg]

    @Relationship(deleteRule: .cascade, inverse: \PackingItem.trip)
    var packingItems: [PackingItem] = []

    @Relationship(deleteRule: .cascade, inverse: \TripDocument.trip)
    var documents: [TripDocument] = []

    @Relationship(deleteRule: .cascade, inverse: \TripTask.trip)
    var tasks: [TripTask] = []

    @Relationship(deleteRule: .cascade, inverse: \TripNote.trip)
    var notesList: [TripNote] = []

    @Relationship(deleteRule: .cascade, inverse: \PerDiemRule.trip)
    var perDiemRule: PerDiemRule?

    static let homeCountryCodeKey = "homeCountryCode"

    /// Computed from the itinerary rather than stored, so it can never
    /// contradict the legs actually entered. `nil` when there's no itinerary yet.
    var tripType: TripType? {
        guard !legs.isEmpty else { return nil }
        let homeCode = UserDefaults.standard.string(forKey: Trip.homeCountryCodeKey) ?? "JP"
        return legs.allSatisfy { $0.countryCode == homeCode } ? .domestic : .international
    }

    init(
        id: UUID = UUID(),
        name: String,
        purpose: String = "",
        baseCurrencyCode: String = "JPY",
        isTemplate: Bool = false,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.purpose = purpose
        self.baseCurrencyCode = baseCurrencyCode
        self.isTemplate = isTemplate
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.legs = []
        self.packingItems = []
        self.documents = []
        self.tasks = []
        self.notesList = []
        self.perDiemRule = nil
    }
}
