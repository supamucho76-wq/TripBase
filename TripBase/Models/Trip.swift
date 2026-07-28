import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID
    var name: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TripLeg.trip)
    var legs: [TripLeg]

    init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.legs = []
    }
}
