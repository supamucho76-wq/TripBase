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

    private func makeTrip(name: String, legs: [TripLeg]) -> Trip {
        let trip = Trip(name: name)
        trip.legs = legs
        return trip
    }

    func testPhaseIsNoItineraryWhenTripHasNoLegs() {
        let trip = makeTrip(name: "empty", legs: [])
        XCTAssertEqual(TripStatusService.phase(of: trip), .noItinerary)
    }

    func testPhaseIsUpcomingBeforeEarliestArrival() {
        let trip = makeTrip(name: "future", legs: [makeLeg(daysFromNow: 3, daysFromNow: 5, city: "a")])
        XCTAssertEqual(TripStatusService.phase(of: trip), .upcoming)
    }

    func testPhaseIsInProgressBetweenLegsEvenIfNoSingleLegSpansNow() {
        // A same-day transfer between two legs should still read as "in progress"
        // even though neither leg's own arrival...departure window contains `now`.
        let trip = makeTrip(name: "transfer", legs: [
            makeLeg(daysFromNow: -2, daysFromNow: -1, city: "a"),
            makeLeg(daysFromNow: 1, daysFromNow: 2, city: "b")
        ])
        XCTAssertEqual(TripStatusService.phase(of: trip), .inProgress)
    }

    func testPhaseIsCompletedAfterLatestDeparture() {
        let trip = makeTrip(name: "past", legs: [makeLeg(daysFromNow: -5, daysFromNow: -3, city: "a")])
        XCTAssertEqual(TripStatusService.phase(of: trip), .completed)
    }

    func testActiveTripReturnsTheInProgressOne() {
        let upcoming = makeTrip(name: "upcoming", legs: [makeLeg(daysFromNow: 3, daysFromNow: 5, city: "a")])
        let active = makeTrip(name: "active", legs: [makeLeg(daysFromNow: -1, daysFromNow: 1, city: "b")])

        let result = TripStatusService.activeTrip(in: [upcoming, active])

        XCTAssertEqual(result?.name, "active")
    }

    func testNextUpcomingTripIsTheEarliestOneExcludingGiven() {
        let excluded = makeTrip(name: "excluded", legs: [makeLeg(daysFromNow: 1, daysFromNow: 2, city: "a")])
        let soonest = makeTrip(name: "soonest", legs: [makeLeg(daysFromNow: 3, daysFromNow: 5, city: "b")])
        let later = makeTrip(name: "later", legs: [makeLeg(daysFromNow: 10, daysFromNow: 12, city: "c")])

        let result = TripStatusService.nextUpcomingTrip(in: [excluded, later, soonest], excluding: excluded)

        XCTAssertEqual(result?.name, "soonest")
    }

    func testMostRecentlyCompletedTripRespectsWindow() {
        let recent = makeTrip(name: "recent", legs: [makeLeg(daysFromNow: -3, daysFromNow: -2, city: "a")])
        let old = makeTrip(name: "old", legs: [makeLeg(daysFromNow: -30, daysFromNow: -29, city: "b")])

        let result = TripStatusService.mostRecentlyCompletedTrip(in: [recent, old], within: 7)

        XCTAssertEqual(result?.name, "recent")
    }
}
