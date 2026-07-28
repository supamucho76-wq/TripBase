import XCTest
@testable import TripBase

final class APICacheTests: XCTestCase {
    struct Sample: Codable, Equatable {
        let value: Int
    }

    private func uniqueKey() -> String {
        "test-\(UUID().uuidString)"
    }

    func testFetchSavesLiveValueForLaterFallback() async {
        let key = uniqueKey()
        let result = await APICache.fetch(key: key) {
            Sample(value: 42)
        }

        XCTAssertEqual(result.value, Sample(value: 42))
        XCTAssertFalse(result.isStale)

        let cached = APICache.load(Sample.self, key: key)
        XCTAssertEqual(cached?.payload, Sample(value: 42))
    }

    func testFetchFallsBackToCacheOnFailure() async {
        let key = uniqueKey()
        APICache.save(Sample(value: 7), key: key)

        let result = await APICache.fetch(key: key) {
            throw URLError(.notConnectedToInternet)
        }

        XCTAssertEqual(result.value, Sample(value: 7))
        XCTAssertTrue(result.isStale)
    }

    func testFetchReturnsNilWhenNoCacheExists() async {
        let key = uniqueKey()

        let result = await APICache.fetch(key: key) {
            throw URLError(.notConnectedToInternet)
        }

        XCTAssertNil(result.value)
        XCTAssertFalse(result.isStale)
    }
}
