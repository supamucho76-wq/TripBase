import Foundation

enum TripStatusService {
    static func currentLeg(in legs: [TripLeg], now: Date = .now) -> TripLeg? {
        legs.first { $0.arrivalDate <= now && now <= $0.departureDate }
    }

    static func nextLeg(in legs: [TripLeg], now: Date = .now) -> TripLeg? {
        legs
            .filter { $0.arrivalDate > now }
            .min { $0.arrivalDate < $1.arrivalDate }
    }

    static func nightsRemaining(for leg: TripLeg, now: Date = .now) -> Int {
        max(0, Calendar.current.dateComponents([.day], from: now, to: leg.departureDate).day ?? 0)
    }

    static func upcomingLegs(in legs: [TripLeg], now: Date = .now, excluding current: TripLeg?) -> [TripLeg] {
        legs
            .filter { $0.id != current?.id && $0.departureDate >= now }
            .sorted { $0.arrivalDate < $1.arrivalDate }
    }
}
