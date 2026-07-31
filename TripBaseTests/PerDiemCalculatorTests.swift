import XCTest
@testable import TripBase

final class PerDiemCalculatorTests: XCTestCase {
    func testSingleDayTripIsEntirelyATravelDay() {
        XCTAssertEqual(PerDiemCalculator.travelDayCount(tripDurationDays: 1), 1)
        XCTAssertEqual(PerDiemCalculator.fullDayCount(tripDurationDays: 1), 0)
    }

    func testTwoDayTripIsTwoTravelDaysWithNoFullDays() {
        XCTAssertEqual(PerDiemCalculator.travelDayCount(tripDurationDays: 2), 2)
        XCTAssertEqual(PerDiemCalculator.fullDayCount(tripDurationDays: 2), 0)
    }

    func testFiveDayTripHasTwoTravelDaysAndThreeFullDays() {
        XCTAssertEqual(PerDiemCalculator.travelDayCount(tripDurationDays: 5), 2)
        XCTAssertEqual(PerDiemCalculator.fullDayCount(tripDurationDays: 5), 3)
    }

    func testTotalCombinesTravelAndFullDayRates() {
        let rule = PerDiemRule(dailyRateAmount: 3000, travelDayRateAmount: 2000)

        let total = PerDiemCalculator.total(rule: rule, tripDurationDays: 5)

        // 2 travel days * 2000 + 3 full days * 3000 = 4000 + 9000 = 13000
        XCTAssertEqual(total, 13_000)
    }

    func testZeroDurationProducesZeroTotal() {
        let rule = PerDiemRule(dailyRateAmount: 3000, travelDayRateAmount: 2000)

        XCTAssertEqual(PerDiemCalculator.total(rule: rule, tripDurationDays: 0), 0)
    }
}
