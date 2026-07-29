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
        XCTAssertTrue(app.buttons["tab.trips"].waitForExistence(timeout: 8))
        app.buttons["tab.trips"].tap()
        XCTAssertTrue(app.navigationBars["出張一覧"].waitForExistence(timeout: 8))

        app.buttons["trip.add"].tap()
        XCTAssertTrue(app.textFields["trip.name"].waitForExistence(timeout: 8))
        app.textFields["trip.name"].tap()
        app.textFields["trip.name"].typeText("台湾出張")
        app.buttons["trip.save"].tap()

        XCTAssertTrue(app.staticTexts["台湾出張"].waitForExistence(timeout: 8))
        app.staticTexts["台湾出張"].tap()

        app.buttons["trip.leg.add"].tap()
        XCTAssertTrue(app.buttons["leg.countryCode"].waitForExistence(timeout: 8))
        app.buttons["leg.countryCode"].tap()
        XCTAssertTrue(app.staticTexts["台湾（TW）"].waitForExistence(timeout: 8))
        app.staticTexts["台湾（TW）"].tap()

        XCTAssertTrue(app.textFields["leg.city"].waitForExistence(timeout: 8))
        app.textFields["leg.city"].tap()
        app.textFields["leg.city"].typeText("台北")
        scrollToButton("leg.save").tap()

        XCTAssertTrue(app.staticTexts["台北"].waitForExistence(timeout: 8))
    }

    @MainActor
    private func scrollToButton(
        _ identifier: String,
        maximumSwipes: Int = 6
    ) -> XCUIElement {
        let button = app.buttons[identifier]
        for _ in 0..<maximumSwipes {
            if button.exists && button.isHittable {
                return button
            }
            app.swipeUp()
        }
        XCTAssertTrue(button.exists, "\(identifier) がスクロール後も見つかりません")
        XCTAssertTrue(button.isHittable, "\(identifier) をタップできません")
        return button
    }
}
