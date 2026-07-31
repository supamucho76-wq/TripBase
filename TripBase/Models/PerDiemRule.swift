import Foundation
import SwiftData

@Model
final class PerDiemRule {
    var id: UUID
    var trip: Trip?
    var currencyCode: String = "JPY"
    var dailyRateAmount: Double = 0
    var travelDayRateAmount: Double = 0
    var notes: String = ""
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        trip: Trip? = nil,
        currencyCode: String = "JPY",
        dailyRateAmount: Double = 0,
        travelDayRateAmount: Double = 0,
        notes: String = ""
    ) {
        self.id = id
        self.trip = trip
        self.currencyCode = currencyCode
        self.dailyRateAmount = dailyRateAmount
        self.travelDayRateAmount = travelDayRateAmount
        self.notes = notes
        self.createdAt = .now
        self.updatedAt = .now
    }
}
