import Foundation

struct PerDiemYearSummary {
    let year: Int
    let totalsByCurrency: [String: Double]
    let tripCount: Int
}

enum PerDiemHistoryService {
    /// Sums each trip's per-diem total (in its own currency, unconverted)
    /// for trips whose itinerary starts in `year`. A trip only counts if it
    /// has both a PerDiemRule and at least one leg.
    static func summary(for year: Int, trips: [Trip], calendar: Calendar = .current) -> PerDiemYearSummary {
        var totalsByCurrency: [String: Double] = [:]
        var tripCount = 0

        for trip in trips {
            guard
                let rule = trip.perDiemRule,
                let firstArrival = trip.legs.map(\.arrivalDate).min(),
                calendar.component(.year, from: firstArrival) == year,
                let durationDays = TripStatusService.tripDurationDays(of: trip, calendar: calendar)
            else {
                continue
            }
            let total = PerDiemCalculator.total(rule: rule, tripDurationDays: durationDays)
            guard total > 0 else { continue }
            totalsByCurrency[rule.currencyCode, default: 0] += total
            tripCount += 1
        }

        return PerDiemYearSummary(year: year, totalsByCurrency: totalsByCurrency, tripCount: tripCount)
    }

    /// Converts every currency bucket to JPY using the given `rate -> JPY`
    /// lookup table (as produced by fetching each currency's forex rate).
    /// Buckets with no known rate are simply skipped from the sum.
    static func jpyTotal(summary: PerDiemYearSummary, ratesToJPY: [String: Double]) -> Double {
        summary.totalsByCurrency.reduce(0) { partialResult, entry in
            let (currency, amount) = entry
            if currency.uppercased() == "JPY" {
                return partialResult + amount
            }
            guard let rate = ratesToJPY[currency] else { return partialResult }
            return partialResult + amount * rate
        }
    }
}
