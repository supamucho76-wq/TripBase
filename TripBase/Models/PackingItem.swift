import Foundation
import SwiftData

enum PackingCategory: String, Codable, CaseIterable, Identifiable {
    case documents
    case electronics
    case clothing
    case toiletries
    case medicine
    case work
    case misc

    var id: String { rawValue }

    var title: String {
        switch self {
        case .documents: "書類・パスポート"
        case .electronics: "電子機器"
        case .clothing: "衣類"
        case .toiletries: "洗面用品"
        case .medicine: "薬"
        case .work: "仕事用品"
        case .misc: "その他"
        }
    }

    var systemImage: String {
        switch self {
        case .documents: "doc.text"
        case .electronics: "cable.connector"
        case .clothing: "tshirt"
        case .toiletries: "drop"
        case .medicine: "cross.case"
        case .work: "briefcase"
        case .misc: "shippingbox"
        }
    }
}

@Model
final class PackingItem {
    var id: UUID
    var trip: Trip?
    var name: String
    var categoryRawValue: String
    var isChecked: Bool
    var orderIndex: Int
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    var category: PackingCategory {
        get { PackingCategory(rawValue: categoryRawValue) ?? .misc }
        set { categoryRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        trip: Trip? = nil,
        name: String,
        category: PackingCategory = .misc,
        isChecked: Bool = false,
        orderIndex: Int = 0,
        notes: String = ""
    ) {
        self.id = id
        self.trip = trip
        self.name = name
        self.categoryRawValue = category.rawValue
        self.isChecked = isChecked
        self.orderIndex = orderIndex
        self.notes = notes
        self.createdAt = .now
        self.updatedAt = .now
    }
}
