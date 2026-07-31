import XCTest
@testable import TripBase

final class PerDiemHistoryServiceTests: XCTestCase {
    private func makeTrip(
        name: String,
        arrivalDate: Date,
        departureDate: Date,
        currencyCode: String,
        dailyRateAmount: Double,
        travelDayRateAmount: Double
    ) -> Trip {
        let trip = Trip(name: name)
        let leg = TripLeg(
            countryCode: "US",
            cityName: "city",
            arrivalDate: arrivalDate,
            departureDate: departureDate,
            orderIndex: 0
        )
        trip.legs = [leg]
        trip.perDiemRule = PerDiemRule(
            trip: trip,
            currencyCode: currencyCode,
            dailyRateAmount: dailyRateAmount,
            travelDayRateAmount: travelDayRateAmount
        )
        return trip
    }

    func testSummingCombinesTripsInTheSameCurrency() {
        let calendar = Calendar.current
        let jan1 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let jan6 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 6))!
        let feb1 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let feb4 = calendar.date(from: DateComponents(year: 2026, month: 2, day: 4))!

        let tripA = makeTrip(name: "A", arrivalDate: jan1, departureDate: jan6, currencyCode: "USD", dailyRateAmount: 100, travelDayRateAmount: 50)
        let tripB = makeTrip(name: "B", arrivalDate: feb1, departureDate: feb4, currencyCode: "USD", dailyRateAmount: 100, travelDayRateAmount: 50)

        let summary = PerDiemHistoryService.summary(for: 2026, trips: [tripA, tripB])

        // Trip A: 6 days -> 2 travel*50 + 4 full*100 = 500
        // Trip B: 4 days -> 2 travel*50 + 2 full*100 = 300
        XCTAssertEqual(summary.totalsByCurrency["USD"], 800)
        XCTAssertEqual(summary.tripCount, 2)
    }

    func testTripsOutsideTheYearAreExcluded() {
        let calendar = Calendar.current
        let lastYearJan = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let lastYearJan5 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 5))!

        let trip = makeTrip(name: "Old", arrivalDate: lastYearJan, departureDate: lastYearJan5, currencyCode: "USD", dailyRateAmount: 100, travelDayRateAmount: 50)

        let summary = PerDiemHistoryService.summary(for: 2026, trips: [trip])

        XCTAssertEqual(summary.tripCount, 0)
        XCTAssertTrue(summary.totalsByCurrency.isEmpty)
    }

    func testTripsWithoutAPerDiemRuleAreExcluded() {
        let calendar = Calendar.current
        let jan1 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let jan5 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 5))!
        let trip = Trip(name: "No rule")
        trip.legs = [TripLeg(countryCode: "US", cityName: "city", arrivalDate: jan1, departureDate: jan5, orderIndex: 0)]

        let summary = PerDiemHistoryService.summary(for: 2026, trips: [trip])

        XCTAssertEqual(summary.tripCount, 0)
    }

    func testJpyTotalConvertsEachCurrencyBucket() {
        let summary = PerDiemYearSummary(year: 2026, totalsByCurrency: ["USD": 100, "JPY": 5000], tripCount: 2)

        let jpyTotal = PerDiemHistoryService.jpyTotal(summary: summary, ratesToJPY: ["USD": 150])

        // 100 USD * 150 + 5000 JPY = 15000 + 5000 = 20000
        XCTAssertEqual(jpyTotal, 20_000)
    }

    func testJpyTotalSkipsCurrenciesWithNoKnownRate() {
        let summary = PerDiemYearSummary(year: 2026, totalsByCurrency: ["USD": 100, "EUR": 50], tripCount: 2)

        let jpyTotal = PerDiemHistoryService.jpyTotal(summary: summary, ratesToJPY: ["USD": 150])

        XCTAssertEqual(jpyTotal, 15_000)
    }
}
