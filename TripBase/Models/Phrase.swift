import Foundation

enum PhraseCategory: String, CaseIterable, Identifiable {
    case hotel
    case airport
    case taxi
    case restaurant
    case emergency

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hotel: "ホテル"
        case .airport: "空港"
        case .taxi: "タクシー"
        case .restaurant: "飲食店"
        case .emergency: "緊急時"
        }
    }

    var systemImage: String {
        switch self {
        case .hotel: "bed.double"
        case .airport: "airplane"
        case .taxi: "car"
        case .restaurant: "fork.knife"
        case .emergency: "exclamationmark.triangle.fill"
        }
    }
}

struct Phrase: Identifiable {
    let id: String
    let category: PhraseCategory
    let japanese: String
    let english: String
}

enum PhraseStore {
    /// English only for now - translating every phrase into every
    /// destination language reliably (especially the emergency category,
    /// where a wrong translation could genuinely matter) needs care beyond
    /// this pass. English is usable as a lingua franca almost everywhere
    /// this app's users travel.
    static let all: [Phrase] = [
        Phrase(id: "hotel-1", category: .hotel, japanese: "予約をしています。", english: "I have a reservation."),
        Phrase(id: "hotel-2", category: .hotel, japanese: "チェックインをお願いします。", english: "I'd like to check in, please."),
        Phrase(id: "hotel-3", category: .hotel, japanese: "チェックアウトは何時ですか？", english: "What time is check-out?"),
        Phrase(id: "hotel-4", category: .hotel, japanese: "Wi-Fiのパスワードを教えてください。", english: "Could you tell me the Wi-Fi password?"),
        Phrase(id: "hotel-5", category: .hotel, japanese: "荷物を預かってもらえますか？", english: "Could you store my luggage, please?"),
        Phrase(id: "hotel-6", category: .hotel, japanese: "タクシーを呼んでもらえますか？", english: "Could you call a taxi for me, please?"),

        Phrase(id: "airport-1", category: .airport, japanese: "チェックインカウンターはどこですか？", english: "Where is the check-in counter?"),
        Phrase(id: "airport-2", category: .airport, japanese: "搭乗ゲートはどこですか？", english: "Where is the boarding gate?"),
        Phrase(id: "airport-3", category: .airport, japanese: "荷物が出てきません。", english: "My luggage hasn't come out."),
        Phrase(id: "airport-4", category: .airport, japanese: "フライトは遅延していますか？", english: "Is the flight delayed?"),
        Phrase(id: "airport-5", category: .airport, japanese: "両替はどこでできますか？", english: "Where can I exchange money?"),

        Phrase(id: "taxi-1", category: .taxi, japanese: "この住所までお願いします。", english: "To this address, please."),
        Phrase(id: "taxi-2", category: .taxi, japanese: "メーターを使ってください。", english: "Please use the meter."),
        Phrase(id: "taxi-3", category: .taxi, japanese: "ここで停めてください。", english: "Please stop here."),
        Phrase(id: "taxi-4", category: .taxi, japanese: "領収書をください。", english: "Could I have a receipt, please?"),
        Phrase(id: "taxi-5", category: .taxi, japanese: "どのくらい時間がかかりますか？", english: "How long will it take?"),

        Phrase(id: "restaurant-1", category: .restaurant, japanese: "2名です。", english: "Table for two, please."),
        Phrase(id: "restaurant-2", category: .restaurant, japanese: "おすすめは何ですか？", english: "What do you recommend?"),
        Phrase(id: "restaurant-3", category: .restaurant, japanese: "辛いものが苦手です。", english: "I can't eat spicy food."),
        Phrase(id: "restaurant-4", category: .restaurant, japanese: "お会計をお願いします。", english: "Check, please."),
        Phrase(id: "restaurant-5", category: .restaurant, japanese: "クレジットカードは使えますか？", english: "Do you accept credit cards?"),

        Phrase(id: "emergency-1", category: .emergency, japanese: "助けてください。", english: "Help me, please."),
        Phrase(id: "emergency-2", category: .emergency, japanese: "具合が悪いです。", english: "I don't feel well."),
        Phrase(id: "emergency-3", category: .emergency, japanese: "救急車を呼んでください。", english: "Please call an ambulance."),
        Phrase(id: "emergency-4", category: .emergency, japanese: "警察を呼んでください。", english: "Please call the police."),
        Phrase(id: "emergency-5", category: .emergency, japanese: "パスポートをなくしました。", english: "I have lost my passport."),
        Phrase(id: "emergency-6", category: .emergency, japanese: "日本大使館に連絡したいです。", english: "I would like to contact the Japanese embassy.")
    ]

    static func phrases(in category: PhraseCategory) -> [Phrase] {
        all.filter { $0.category == category }
    }
}
