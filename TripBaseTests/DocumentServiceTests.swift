import XCTest
@testable import TripBase

final class DocumentServiceTests: XCTestCase {
    private func makeDocument(daysUntilExpiry: Int?) -> TripDocument {
        let expiryDate = daysUntilExpiry.map { Date.now.addingTimeInterval(TimeInterval($0) * 86_400) }
        return TripDocument(name: "doc", category: .passport, expiryDate: expiryDate)
    }

    func testStatusIsOkWhenNoExpiryDateIsSet() {
        let document = makeDocument(daysUntilExpiry: nil)
        XCTAssertEqual(DocumentService.status(for: document), .ok)
    }

    func testStatusIsOkWellBeforeExpiry() {
        let document = makeDocument(daysUntilExpiry: 400)
        XCTAssertEqual(DocumentService.status(for: document), .ok)
    }

    func testStatusIsExpiringSoonWithinTheWarningWindow() {
        let document = makeDocument(daysUntilExpiry: 90)
        XCTAssertEqual(DocumentService.status(for: document), .expiringSoon)
    }

    func testStatusIsExpiredAfterExpiryDate() {
        let document = makeDocument(daysUntilExpiry: -1)
        XCTAssertEqual(DocumentService.status(for: document), .expired)
    }

    func testUnconfirmedCountCountsOnlyUnconfirmedDocuments() {
        let confirmed = TripDocument(name: "a", category: .flight, isConfirmed: true)
        let unconfirmed = TripDocument(name: "b", category: .hotel, isConfirmed: false)

        XCTAssertEqual(DocumentService.unconfirmedCount([confirmed, unconfirmed]), 1)
    }
}
