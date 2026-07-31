import Foundation
import SwiftData

enum DocumentCategory: String, Codable, CaseIterable, Identifiable {
    case flight
    case hotel
    case passport
    case visa
    case insurance
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flight: "航空券"
        case .hotel: "ホテル"
        case .passport: "パスポート"
        case .visa: "ビザ"
        case .insurance: "海外旅行保険"
        case .other: "その他書類"
        }
    }

    var systemImage: String {
        switch self {
        case .flight: "airplane.departure"
        case .hotel: "bed.double"
        case .passport: "person.text.rectangle"
        case .visa: "checkmark.seal"
        case .insurance: "cross.case"
        case .other: "doc.text"
        }
    }
}

@Model
final class TripDocument {
    var id: UUID
    var trip: Trip?
    var categoryRawValue: String
    var name: String
    var referenceNumber: String
    var expiryDate: Date?
    var notes: String
    var isConfirmed: Bool
    var orderIndex: Int
    var attachmentFileName: String?
    var attachmentOriginalFileName: String = ""
    var createdAt: Date
    var updatedAt: Date

    var category: DocumentCategory {
        get { DocumentCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    var hasAttachment: Bool {
        attachmentFileName != nil
    }

    init(
        id: UUID = UUID(),
        trip: Trip? = nil,
        name: String,
        category: DocumentCategory,
        referenceNumber: String = "",
        expiryDate: Date? = nil,
        notes: String = "",
        isConfirmed: Bool = false,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.trip = trip
        self.name = name
        self.categoryRawValue = category.rawValue
        self.referenceNumber = referenceNumber
        self.expiryDate = expiryDate
        self.notes = notes
        self.isConfirmed = isConfirmed
        self.orderIndex = orderIndex
        self.attachmentFileName = nil
        self.attachmentOriginalFileName = ""
        self.createdAt = .now
        self.updatedAt = .now
    }
}
