import XCTest
@testable import TripBase

final class TimezoneServiceTests: XCTestCase {
    func testHourDifferenceIsZeroForSameTimeZone() {
        let diff = TimezoneService.hourDifference(destinationIdentifier: "Asia/Tokyo")
        XCTAssertEqual(diff, 0)
    }

    func testHourDifferenceForParisIsNegative() {
        // Japan (UTC+9) is always ahead of Paris (UTC+1 or UTC+2), regardless of DST.
        let diff = TimezoneService.hourDifference(destinationIdentifier: "Europe/Paris")
        XCTAssertNotNil(diff)
        XCTAssertTrue((diff ?? 0) < 0)
    }

    func testCurrentTimeReturnsNilForUnknownIdentifier() {
        XCTAssertNil(TimezoneService.currentTime(destinationIdentifier: "Not/AZone"))
    }
}
