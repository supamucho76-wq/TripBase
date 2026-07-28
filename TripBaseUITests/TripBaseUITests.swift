import XCTest

final class TripBaseUITests: XCTestCase {
    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["出張コンパス"].waitForExistence(timeout: 8))
    }
}
