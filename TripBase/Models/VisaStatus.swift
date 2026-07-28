import Foundation

enum VisaStatus: String, Codable, CaseIterable, Identifiable {
    case notRequired
    case eTA
    case visaOnArrival
    case applied
    case approved
    case required

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notRequired: "不要"
        case .eTA: "ETA申請"
        case .visaOnArrival: "到着ビザ"
        case .applied: "申請中"
        case .approved: "取得済み"
        case .required: "要確認"
        }
    }

    var systemImage: String {
        switch self {
        case .notRequired: "checkmark.circle"
        case .eTA: "airplane.departure"
        case .visaOnArrival: "airplane.arrival"
        case .applied: "clock"
        case .approved: "checkmark.seal"
        case .required: "exclamationmark.triangle"
        }
    }
}
