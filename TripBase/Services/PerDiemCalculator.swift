import Foundation

enum PerDiemCalculator {
    /// The first and last day of a trip are conventionally paid at a
    /// reduced "travel day" rate (you're not at the destination for the
    /// whole day). Every day in between is a full day. A 1-day trip is
    /// entirely a travel day; a 2-day trip is two travel days with no full
    /// days in between.
    static func travelDayCount(tripDurationDays: Int) -> Int {
        min(2, max(0, tripDurationDays))
    }

    static func fullDayCount(tripDurationDays: Int) -> Int {
        max(0, tripDurationDays - 2)
    }

    static func total(rule: PerDiemRule, tripDurationDays: Int) -> Double {
        let travelDays = travelDayCount(tripDurationDays: tripDurationDays)
        let fullDays = fullDayCount(tripDurationDays: tripDurationDays)
        return Double(travelDays) * rule.travelDayRateAmount + Double(fullDays) * rule.dailyRateAmount
    }
}
