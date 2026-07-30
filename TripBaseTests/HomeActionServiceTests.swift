import XCTest
@testable import TripBase

final class HomeActionServiceTests: XCTestCase {
    private func makeLeg(
        countryCode: String = "TW",
        visaStatus: VisaStatus = .notRequired,
        hotelName: String = "",
        hotelAddress: String = "",
        transportNote: String = "",
        daysFromNow start: Int,
        daysFromNow end: Int
    ) -> TripLeg {
        let now = Date.now
        let leg = TripLeg(
            countryCode: countryCode,
            cityName: "city",
            arrivalDate: now.addingTimeInterval(TimeInterval(start) * 86_400),
            departureDate: now.addingTimeInterval(TimeInterval(end) * 86_400),
            orderIndex: 0
        )
        leg.visaStatus = visaStatus
        leg.hotelName = hotelName
        leg.hotelAddress = hotelAddress
        leg.transportNote = transportNote
        return leg
    }

    private func makeTrip(legs: [TripLeg]) -> Trip {
        let trip = Trip(name: "trip")
        trip.legs = legs
        return trip
    }

    func testVisaTakesPriorityOverEverythingElse() {
        let leg = makeLeg(
            visaStatus: .required,
            hotelName: "",
            transportNote: "",
            daysFromNow: 10,
            daysFromNow: 15
        )
        let trip = makeTrip(legs: [leg])

        let action = HomeActionService.topPriorityAction(trip: trip, leg: leg, flightCheckinDone: false)

        XCTAssertEqual(action?.id, "visa")
    }

    func testHotelMissingTakesPriorityOverTransportAndPacking() {
        let leg = makeLeg(hotelName: "", transportNote: "", daysFromNow: 10, daysFromNow: 15)
        let trip = makeTrip(legs: [leg])
        trip.packingItems = [PackingItem(trip: trip, name: "item", category: .misc, orderIndex: 0)]

        let action = HomeActionService.topPriorityAction(trip: trip, leg: leg, flightCheckinDone: false)

        XCTAssertEqual(action?.id, "hotel")
    }

    func testTransportMissingSurfacesOnceHotelIsRegistered() {
        let leg = makeLeg(hotelName: "Some Hotel", transportNote: "", daysFromNow: 10, daysFromNow: 15)
        let trip = makeTrip(legs: [leg])

        let action = HomeActionService.topPriorityAction(trip: trip, leg: leg, flightCheckinDone: false)

        XCTAssertEqual(action?.id, "transport")
    }

    func testDepartureSoonSurfacesOnceReservationsAreRegistered() {
        let leg = makeLeg(hotelName: "Hotel", transportNote: "ANA123", daysFromNow: 2, daysFromNow: 5)
        let trip = makeTrip(legs: [leg])

        let action = HomeActionService.topPriorityAction(trip: trip, leg: leg, flightCheckinDone: false)

        XCTAssertEqual(action?.id, "departure-soon")
    }

    func testPackingSurfacesWhenNothingElseIsPending() {
        let leg = makeLeg(hotelName: "Hotel", transportNote: "ANA123", daysFromNow: 20, daysFromNow: 25)
        let trip = makeTrip(legs: [leg])
        let item = PackingItem(trip: trip, name: "item", category: .misc, orderIndex: 0)
        trip.packingItems = [item]

        let action = HomeActionService.topPriorityAction(trip: trip, leg: leg, flightCheckinDone: false)

        XCTAssertEqual(action?.id, "packing")
    }

    func testReturnsNilWhenEverythingIsDone() {
        let leg = makeLeg(hotelName: "Hotel", transportNote: "ANA123", daysFromNow: 20, daysFromNow: 25)
        let trip = makeTrip(legs: [leg])
        let item = PackingItem(trip: trip, name: "item", category: .misc, orderIndex: 0)
        item.isChecked = true
        trip.packingItems = [item]

        let action = HomeActionService.topPriorityAction(trip: trip, leg: leg, flightCheckinDone: true)

        XCTAssertNil(action)
    }
}
