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

        if leg.visaStatus == .required || leg.visaStatus == .applied {
            items.append(
                HomeActionItem(id: "visa", title: "ビザ状況を確認してください", systemImage: "exclamationmark.triangle", isDone: false, kind: .navigate)
            )
        }

        let hotelInfoRegistered = hasHotelInfo(leg)
        items.append(
            HomeActionItem(
                id: "hotel",
                title: hotelInfoRegistered ? "ホテル情報登録済み" : "ホテル情報が未登録です",
                systemImage: "bed.double",
                isDone: hotelInfoRegistered,
                kind: .navigate
            )
        )

        let transportInfoRegistered = hasTransportInfo(leg)
        items.append(
            HomeActionItem(
                id: "transport",
                title: transportInfoRegistered ? "移動手段の予約情報登録済み" : "航空券・移動手段の予約情報が未登録です",
                systemImage: "airplane.departure",
                isDone: transportInfoRegistered,
                kind: .navigate
            )
        )

        let packingItems = trip.packingItems
        if !packingItems.isEmpty {
            let remaining = packingItems.filter { !$0.isChecked }.count
            items.append(
                HomeActionItem(
                    id: "packing",
                    title: remaining == 0 ? "持ち物 準備完了" : "持ち物が残り\(remaining)件あります",
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

    /// The single most urgent unfinished item, in priority order:
    /// required documents (proxied by visa status) > flight/hotel
    /// reservations > an imminent-departure nudge > packing > everything
    /// else. `nil` means nothing needs attention right now.
    static func topPriorityAction(trip: Trip, leg: TripLeg, flightCheckinDone: Bool, now: Date = .now) -> HomeActionItem? {
        if leg.visaStatus == .required || leg.visaStatus == .applied {
            return HomeActionItem(id: "visa", title: "ビザ状況を確認してください", systemImage: "exclamationmark.triangle", isDone: false, kind: .navigate)
        }

        if !hasHotelInfo(leg) {
            return HomeActionItem(id: "hotel", title: "ホテル情報が未登録です", systemImage: "bed.double", isDone: false, kind: .navigate)
        }

        if !hasTransportInfo(leg) {
            return HomeActionItem(id: "transport", title: "航空券・移動手段の予約情報が未登録です", systemImage: "airplane.departure", isDone: false, kind: .navigate)
        }

        if TripStatusService.phase(of: trip, now: now) == .upcoming,
           let daysLeft = TripStatusService.daysUntilDeparture(of: trip, now: now),
           daysLeft <= 3 {
            return HomeActionItem(
                id: "departure-soon",
                title: daysLeft == 0 ? "本日出発です" : "出発\(daysLeft)日前です",
                systemImage: "airplane",
                isDone: false,
                kind: .navigate
            )
        }

        let packingItems = trip.packingItems
        if !packingItems.isEmpty {
            let remaining = packingItems.filter { !$0.isChecked }.count
            if remaining > 0 {
                return HomeActionItem(id: "packing", title: "持ち物が残り\(remaining)件あります", systemImage: "checklist", isDone: false, kind: .navigate)
            }
        }

        if shouldShowFlightCheckin(leg: leg, now: now), !flightCheckinDone {
            return HomeActionItem(id: "flight-checkin", title: "フライトチェックインをお済ませください", systemImage: "airplane", isDone: false, kind: .toggle)
        }

        return nil
    }

    static func hasHotelInfo(_ leg: TripLeg) -> Bool {
        !leg.hotelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !leg.hotelAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func hasTransportInfo(_ leg: TripLeg) -> Bool {
        !leg.transportNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
