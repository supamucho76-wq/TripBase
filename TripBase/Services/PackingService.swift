import Foundation

enum PackingService {
    static func percentComplete(_ items: [PackingItem]) -> Double {
        guard !items.isEmpty else { return 0 }
        let checkedCount = items.filter(\.isChecked).count
        return Double(checkedCount) / Double(items.count)
    }

    static func isUrgent(trip: Trip, now: Date = .now) -> Bool {
        guard let firstArrival = trip.legs.map(\.arrivalDate).min() else { return false }
        let calendar = Calendar.current
        let daysUntil = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: firstArrival)
        ).day ?? Int.max
        return daysUntil >= 0 && daysUntil <= 1
    }

    enum QuickTemplate: String, CaseIterable, Identifiable {
        case domestic
        case international
        case longTrip

        var id: String { rawValue }

        var title: String {
            switch self {
            case .domestic: "国内出張"
            case .international: "海外出張"
            case .longTrip: "長期出張"
            }
        }

        var items: [(name: String, category: PackingCategory)] {
            switch self {
            case .domestic:
                [
                    ("名刺", .work), ("PC・充電器", .electronics), ("着替え", .clothing),
                    ("洗面用具", .toiletries), ("常備薬", .medicine)
                ]
            case .international:
                [
                    ("パスポート", .documents), ("ビザ・控え", .documents), ("海外保険証", .documents),
                    ("変換プラグ", .electronics), ("PC・充電器", .electronics), ("常備薬", .medicine),
                    ("着替え", .clothing), ("洗面用具", .toiletries), ("現地通貨", .misc)
                ]
            case .longTrip:
                [
                    ("パスポート", .documents), ("ビザ・控え", .documents), ("海外保険証", .documents),
                    ("変換プラグ", .electronics), ("PC・充電器", .electronics), ("常備薬", .medicine),
                    ("着替え（多め）", .clothing), ("洗面用具", .toiletries), ("洗濯用品", .misc),
                    ("現地通貨", .misc), ("常備食", .misc)
                ]
            }
        }
    }
}
