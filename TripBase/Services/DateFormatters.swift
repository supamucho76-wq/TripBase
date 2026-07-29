import Foundation

enum DateFormatPreference: String, CaseIterable, Identifiable {
    case gregorian
    case japaneseEra
    case localeNative

    static let storageKey = "dateFormatPreference"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gregorian: "西暦"
        case .japaneseEra: "和暦"
        case .localeNative: "現地形式"
        }
    }
}

@MainActor
enum AppDateFormatter {
    static var preference: DateFormatPreference {
        UserDefaults.standard.string(forKey: DateFormatPreference.storageKey)
            .flatMap(DateFormatPreference.init(rawValue:)) ?? .gregorian
    }

    static var date: DateFormatter {
        let formatter = DateFormatter()
        switch preference {
        case .gregorian:
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.dateFormat = "yyyy年M月d日"
        case .japaneseEra:
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.calendar = Calendar(identifier: .japanese)
            formatter.dateFormat = "Gy年M月d日"
        case .localeNative:
            formatter.locale = .autoupdatingCurrent
            formatter.dateStyle = .long
            formatter.timeStyle = .none
        }
        return formatter
    }

    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/M/d HH:mm"
        return formatter
    }()

    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter
    }()
}
