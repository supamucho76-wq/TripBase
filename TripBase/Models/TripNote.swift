import Foundation
import SwiftData

enum NoteCategory: String, Codable, CaseIterable, Identifiable {
    case wholeTrip
    case hotel
    case transport
    case destination
    case localLife
    case nextTime
    case caution

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wholeTrip: "出張全体"
        case .hotel: "ホテル"
        case .transport: "移動"
        case .destination: "目的地"
        case .localLife: "現地の暮らし"
        case .nextTime: "次回への引き継ぎ"
        case .caution: "注意点"
        }
    }

    var systemImage: String {
        switch self {
        case .wholeTrip: "note.text"
        case .hotel: "bed.double"
        case .transport: "car"
        case .destination: "mappin.and.ellipse"
        case .localLife: "house"
        case .nextTime: "arrow.uturn.forward"
        case .caution: "exclamationmark.triangle"
        }
    }
}

@Model
final class TripNote {
    var id: UUID
    var trip: Trip?
    var categoryRawValue: String
    var title: String
    var body: String
    var isPinned: Bool
    var createdAt: Date
    var updatedAt: Date

    var category: NoteCategory {
        get { NoteCategory(rawValue: categoryRawValue) ?? .wholeTrip }
        set { categoryRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        trip: Trip? = nil,
        title: String,
        body: String = "",
        category: NoteCategory = .wholeTrip,
        isPinned: Bool = false
    ) {
        self.id = id
        self.trip = trip
        self.title = title
        self.body = body
        self.categoryRawValue = category.rawValue
        self.isPinned = isPinned
        self.createdAt = .now
        self.updatedAt = .now
    }
}
