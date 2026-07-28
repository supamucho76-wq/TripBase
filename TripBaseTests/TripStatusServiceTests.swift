import XCTest
@testable import TripBase

final class TripStatusServiceTests: XCTestCase {
    private func makeLeg(daysFromNow start: Int, daysFromNow end: Int, city: String) -> TripLeg {
        let now = Date.now
        return TripLeg(
            countryCode: "JP",
            cityName: city,
            arrivalDate: now.addingTimeInterval(TimeInterval(start) * 86_400),
            departureDate: now.addingTimeInterval(TimeInterval(end) * 86_400),
            orderIndex: 0
        )
    }

    func testCurrentLegIsTheOneSpanningNow() {
        let past = makeLeg(daysFromNow: -3, daysFromNow: -1, city: "past")
        let current = makeLeg(daysFromNow: -1, daysFromNow: 2, city: "current")
        let future = makeLeg(daysFromNow: 3, daysFromNow: 5, city: "future")

        let result = TripStatusService.currentLeg(in: [past, current, future])

        XCTAssertEqual(result?.cityName, "current")
    }

    func testNextLegIsTheEarliestUpcomingOne() {
        let current = makeLeg(daysFromNow: -1, daysFromNow: 1, city: "current")
        let soonest = makeLeg(daysFromNow: 3, daysFromNow: 5, city: "soonest")
        let later = makeLeg(daysFromNow: 10, daysFromNow: 12, city: "later")

        let result = TripStatusService.nextLeg(in: [current, later, soonest])

        XCTAssertEqual(result?.cityName, "soonest")
    }

    func testNightsRemainingNeverGoesNegative() {
        let leg = makeLeg(daysFromNow: -5, daysFromNow: -1, city: "ended")

        XCTAssertEqual(TripStatusService.nightsRemaining(for: leg), 0)
    }

    func testUpcomingLegsExcludesCurrentAndPastLegs() {
        let past = makeLeg(daysFromNow: -5, daysFromNow: -3, city: "past")
        let current = makeLeg(daysFromNow: -1, daysFromNow: 1, city: "current")
        let upcoming = makeLeg(daysFromNow: 3, daysFromNow: 5, city: "upcoming")

        let result = TripStatusService.upcomingLegs(in: [past, current, upcoming], excluding: current)

        XCTAssertEqual(result.map(\.cityName), ["upcoming"])
    }
}
