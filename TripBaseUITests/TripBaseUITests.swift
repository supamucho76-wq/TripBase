import XCTest

final class TripBaseUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
    }

    @MainActor
    func testCreateTripAndLeg() throws {
        XCTAssertTrue(app.navigationBars["出張一覧"].waitForExistence(timeout: 8))

        app.buttons["trip.add"].tap()
        XCTAssertTrue(app.textFields["trip.name"].waitForExistence(timeout: 8))
        app.textFields["trip.name"].tap()
        app.textFields["trip.name"].typeText("台湾出張")
        app.buttons["trip.save"].tap()

        XCTAssertTrue(app.staticTexts["台湾出張"].waitForExistence(timeout: 8))
        app.staticTexts["台湾出張"].tap()

        app.buttons["trip.leg.add"].tap()
        XCTAssertTrue(app.textFields["leg.city"].waitForExistence(timeout: 8))
        app.textFields["leg.city"].tap()
        app.textFields["leg.city"].typeText("台北")
        app.textFields["leg.countryCode"].tap()
        app.textFields["leg.countryCode"].typeText("TW")
        app.buttons["leg.save"].tap()

        XCTAssertTrue(app.staticTexts["台北"].waitForExistence(timeout: 8))
    }
}
