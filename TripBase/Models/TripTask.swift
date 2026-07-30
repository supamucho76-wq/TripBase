import Foundation
import SwiftData

enum TaskPhase: String, Codable, CaseIterable, Identifiable {
    case beforeTrip
    case duringTrip
    case afterTrip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beforeTrip: "出張前"
        case .duringTrip: "出張中"
        case .afterTrip: "帰国後"
        }
    }
}

@Model
final class TripTask {
    var id: UUID
    var trip: Trip?
    var title: String
    var phaseRawValue: String
    var isDone: Bool
    var notes: String
    var orderIndex: Int
    var createdAt: Date
    var updatedAt: Date

    var phase: TaskPhase {
        get { TaskPhase(rawValue: phaseRawValue) ?? .beforeTrip }
        set { phaseRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        trip: Trip? = nil,
        title: String,
        phase: TaskPhase = .beforeTrip,
        isDone: Bool = false,
        notes: String = "",
        orderIndex: Int = 0
    ) {
        self.id = id
        self.trip = trip
        self.title = title
        self.phaseRawValue = phase.rawValue
        self.isDone = isDone
        self.notes = notes
        self.orderIndex = orderIndex
        self.createdAt = .now
        self.updatedAt = .now
    }
}
