import Foundation
import SwiftData

enum LocalPlaceCategory: String, Codable, CaseIterable, Identifiable {
    case workplace
    case airport
    case taxi
    case hospital
    case convenience
    case laundry
    case gym
    case restaurant
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .workplace: "勤務先・訪問先"
        case .airport: "空港・駅"
        case .taxi: "よく使うタクシー行き先"
        case .hospital: "病院"
        case .convenience: "コンビニ・スーパー"
        case .laundry: "ランドリー"
        case .gym: "ジム"
        case .restaurant: "飲食店"
        case .other: "その他"
        }
    }

    var systemImage: String {
        switch self {
        case .workplace: "building.2"
        case .airport: "airplane"
        case .taxi: "car"
        case .hospital: "cross.case"
        case .convenience: "cart"
        case .laundry: "washer"
        case .gym: "figure.run"
        case .restaurant: "fork.knife"
        case .other: "mappin.and.ellipse"
        }
    }
}

@Model
final class LocalPlace {
    var id: UUID
    var tripLeg: TripLeg?
    var name: String
    var categoryRawValue: String
    var address: String
    var phone: String
    var notes: String
    var orderIndex: Int
    var createdAt: Date

    var category: LocalPlaceCategory {
        get { LocalPlaceCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        tripLeg: TripLeg? = nil,
        name: String,
        category: LocalPlaceCategory = .other,
        address: String = "",
        phone: String = "",
        notes: String = "",
        orderIndex: Int = 0
    ) {
        self.id = id
        self.tripLeg = tripLeg
        self.name = name
        self.categoryRawValue = category.rawValue
        self.address = address
        self.phone = phone
        self.notes = notes
        self.orderIndex = orderIndex
        self.createdAt = .now
    }
}
