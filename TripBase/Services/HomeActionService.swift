import Foundation

struct HomeActionItem: Identifiable {
    enum Kind: Equatable {
        case navigate
        case toggle
    }

    let id: String
    let title: String
    let systemImage: String
    let isDone: Bool
    let kind: Kind
}

enum HomeActionService {
    static func actionItems(trip: Trip, leg: TripLeg?, flightCheckinDone: Bool, now: Date = .now) -> [HomeActionItem] {
        guard let leg else {
            return [
                HomeActionItem(id: "add-leg", title: "行程を追加", systemImage: "mappin.and.ellipse", isDone: false, kind: .navigate)
            ]
        }

        var items: [HomeActionItem] = []

        let hasHotelInfo = !leg.hotelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !leg.hotelAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        items.append(
            HomeActionItem(
                id: "hotel",
                title: hasHotelInfo ? "ホテル情報登録済み" : "ホテル情報を登録",
                systemImage: "bed.double",
                isDone: hasHotelInfo,
                kind: .navigate
            )
        )

        if leg.visaStatus == .required || leg.visaStatus == .applied {
            items.append(
                HomeActionItem(id: "visa", title: "ビザ状況を確認", systemImage: "exclamationmark.triangle", isDone: false, kind: .navigate)
            )
        }

        let packingItems = trip.packingItems
        if !packingItems.isEmpty {
            let remaining = packingItems.filter { !$0.isChecked }.count
            items.append(
                HomeActionItem(
                    id: "packing",
                    title: remaining == 0 ? "持ち物 準備完了" : "持ち物 残り\(remaining)件",
                    systemImage: "checklist",
                    isDone: remaining == 0,
                    kind: .navigate
                )
            )
        }

        if shouldShowFlightCheckin(leg: leg, now: now) {
            items.append(
                HomeActionItem(id: "flight-checkin", title: "フライトチェックイン", systemImage: "airplane", isDone: flightCheckinDone, kind: .toggle)
            )
        }

        return items
    }

    static func shouldShowFlightCheckin(leg: TripLeg, now: Date = .now) -> Bool {
        let calendar = Calendar.current
        let daysToArrival = calendar.dateComponents([.day], from: now, to: leg.arrivalDate).day ?? Int.max
        let daysToDeparture = calendar.dateComponents([.day], from: now, to: leg.departureDate).day ?? Int.max
        return (daysToArrival >= 0 && daysToArrival <= 2) || (daysToDeparture >= 0 && daysToDeparture <= 2)
    }

    static func flightCheckinKey(tripID: UUID, legID: UUID) -> String {
        "flightCheckin-\(tripID)-\(legID)"
    }
}
