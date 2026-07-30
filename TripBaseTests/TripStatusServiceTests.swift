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

    // MARK: - Day-boundary correctness

    /// Arrival stored with a late time-of-day (e.g. a DatePicker value picked
    /// in the evening) should still read as "upcoming", not "inProgress",
    /// right up until midnight - and "inProgress" for the whole of the
    /// arrival day regardless of what time `now` is.
    func testPhaseIsUpcomingUntilMidnightBeforeArrivalDayRegardlessOfTimeOfDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let arrivalTomorrowEvening = calendar.date(byAdding: .hour, value: 44, to: today)! // tomorrow ~20:00
        let departure = calendar.date(byAdding: .day, value: 3, to: today)!
        let trip = makeTrip(name: "evening-arrival", legs: [
            TripLeg(countryCode: "JP", cityName: "a", arrivalDate: arrivalTomorrowEvening, departureDate: departure, orderIndex: 0)
        ])

        XCTAssertEqual(TripStatusService.phase(of: trip, now: today), .upcoming)
    }

    func testPhaseIsInProgressForEntireDepartureDayRegardlessOfTimeOfDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let arrival = calendar.date(byAdding: .day, value: -2, to: today)!
        let departureThisMorning = calendar.date(byAdding: .hour, value: 6, to: today)!
        let trip = makeTrip(name: "morning-departure", legs: [
            TripLeg(countryCode: "JP", cityName: "a", arrivalDate: arrival, departureDate: departureThisMorning, orderIndex: 0)
        ])
        // "now" is later the same day, after the stored departure time.
        let laterToday = calendar.date(byAdding: .hour, value: 20, to: today)!

        XCTAssertEqual(TripStatusService.phase(of: trip, now: laterToday), .inProgress)
    }

    func testDaysUntilDepartureAndReturn() {
        let trip = makeTrip(name: "trip", legs: [makeLeg(daysFromNow: 3, daysFromNow: 6, city: "a")])

        XCTAssertEqual(TripStatusService.daysUntilDeparture(of: trip), 3)
        XCTAssertEqual(TripStatusService.daysUntilReturn(of: trip), 6)
    }

    func testDayNumberIsOneOnArrivalDayAndNilBeforeTripStarts() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let trip = makeTrip(name: "trip", legs: [makeLeg(daysFromNow: 0, daysFromNow: 4, city: "a")])
        let upcomingTrip = makeTrip(name: "upcoming", legs: [makeLeg(daysFromNow: 2, daysFromNow: 4, city: "a")])

        XCTAssertEqual(TripStatusService.dayNumber(of: trip, now: today), 1)
        let thirdDay = calendar.date(byAdding: .day, value: 2, to: today)!
        XCTAssertEqual(TripStatusService.dayNumber(of: trip, now: thirdDay), 3)
        XCTAssertNil(TripStatusService.dayNumber(of: upcomingTrip, now: today))
    }

    func testTripDurationDaysAndTotalNightsAreInclusiveOfBothEndpoints() {
        let trip = makeTrip(name: "trip", legs: [makeLeg(daysFromNow: 0, daysFromNow: 4, city: "a")])

        XCTAssertEqual(TripStatusService.tripDurationDays(of: trip), 5)
        XCTAssertEqual(TripStatusService.totalNights(of: trip), 4)
    }

    func testSameDayTripHasOneDurationDayAndZeroNights() {
        let trip = makeTrip(name: "day-trip", legs: [makeLeg(daysFromNow: 2, daysFromNow: 2, city: "a")])

        XCTAssertEqual(TripStatusService.tripDurationDays(of: trip), 1)
        XCTAssertEqual(TripStatusService.totalNights(of: trip), 0)
    }
}
