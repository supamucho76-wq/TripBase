import SwiftData
import XCTest
@testable import TripBase

@MainActor
final class TripDuplicationServiceTests: XCTestCase {
    private func makeContext() -> ModelContext {
        let schema = Schema([
            Trip.self, TripLeg.self, PackingItem.self, LocalPlace.self,
            TripDocument.self, TripTask.self, TripNote.self, PerDiemRule.self
        ])
        let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        return ModelContext(container)
    }

    private func makeSourceTrip(in context: ModelContext) -> Trip {
        let trip = Trip(name: "台湾出張", purpose: "商談", baseCurrencyCode: "TWD")
        context.insert(trip)

        let leg = TripLeg(countryCode: "TW", cityName: "台中", arrivalDate: .now, departureDate: .now.addingTimeInterval(3 * 86_400), orderIndex: 0, trip: trip)
        leg.hotelName = "Hotel"
        leg.hotelBookingReference = "ABC123"
        leg.visaStatus = .approved
        trip.legs.append(leg)

        let packingItem = PackingItem(trip: trip, name: "パスポート", category: .documents, isChecked: true, orderIndex: 0)
        trip.packingItems.append(packingItem)

        let document = TripDocument(trip: trip, name: "航空券", category: .flight, referenceNumber: "XYZ", isConfirmed: true, orderIndex: 0)
        trip.documents.append(document)

        let task = TripTask(trip: trip, title: "有給申請", phase: .beforeTrip, isDone: true)
        trip.tasks.append(task)

        trip.perDiemRule = PerDiemRule(trip: trip, currencyCode: "TWD", dailyRateAmount: 3000, travelDayRateAmount: 1500)

        return trip
    }

    func testDuplicateCopiesStructureAndResetsCompletionState() {
        let context = makeContext()
        let source = makeSourceTrip(in: context)

        let copy = TripDuplicationService.duplicate(source: source, asTemplate: false, in: context)

        XCTAssertFalse(copy.isTemplate)
        XCTAssertEqual(copy.baseCurrencyCode, "TWD")
        XCTAssertEqual(copy.legs.count, 1)
        XCTAssertEqual(copy.legs.first?.cityName, "台中")
        XCTAssertEqual(copy.legs.first?.hotelName, "Hotel")
        XCTAssertEqual(copy.legs.first?.hotelBookingReference, "", "booking reference is trip-specific, shouldn't carry over")
        XCTAssertEqual(copy.legs.first?.visaStatus, .notRequired, "visa status is trip-specific, shouldn't carry over")

        XCTAssertEqual(copy.packingItems.count, 1)
        XCTAssertFalse(copy.packingItems.first?.isChecked ?? true)

        XCTAssertEqual(copy.documents.count, 1)
        XCTAssertFalse(copy.documents.first?.isConfirmed ?? true)
        XCTAssertEqual(copy.documents.first?.referenceNumber, "", "reference number is trip-specific, shouldn't carry over")

        XCTAssertEqual(copy.tasks.count, 1)
        XCTAssertFalse(copy.tasks.first?.isDone ?? true)

        XCTAssertEqual(copy.perDiemRule?.dailyRateAmount, 3000)
    }

    func testDuplicateAsTemplateSetsTheFlag() {
        let context = makeContext()
        let source = makeSourceTrip(in: context)

        let template = TripDuplicationService.duplicate(source: source, asTemplate: true, in: context)

        XCTAssertTrue(template.isTemplate)
        XCTAssertTrue(template.name.contains("テンプレート"))
    }
}
