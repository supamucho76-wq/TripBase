import Foundation
import SwiftData

// Phase-2/stretch feature, not yet confirmed for MVP. Defined now so the
// schema migration path exists later, but intentionally NOT added to
// TripBaseApp's Schema([...]) until the per-diem feature is greenlit.
@Model
final class PerDiemEntry {
    var id: UUID
    var date: Date
    var amountJPY: Double
    var category: String
    var tripLeg: TripLeg?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        amountJPY: Double,
        category: String = "",
        tripLeg: TripLeg? = nil
    ) {
        self.id = id
        self.date = date
        self.amountJPY = amountJPY
        self.category = category
        self.tripLeg = tripLeg
    }
}
