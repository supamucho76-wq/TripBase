import Foundation

enum TripPhase {
    case noItinerary
    case upcoming
    case inProgress
    case completed
}

enum TripStatusService {
    /// Computed from the trip's own legs rather than stored, so editing dates
    /// can never leave a stale status behind.
    static func phase(of trip: Trip, now: Date = .now) -> TripPhase {
        guard !trip.legs.isEmpty else { return .noItinerary }
        guard
            let earliestArrival = trip.legs.map(\.arrivalDate).min(),
            let latestDeparture = trip.legs.map(\.departureDate).max()
        else {
            return .noItinerary
        }
        if now < earliestArrival { return .upcoming }
        if now > latestDeparture { return .completed }
        return .inProgress
    }

    static func activeTrip(in trips: [Trip], now: Date = .now) -> Trip? {
        trips.first { phase(of: $0, now: now) == .inProgress }
    }

    static func nextUpcomingTrip(in trips: [Trip], excluding: Trip? = nil, now: Date = .now) -> Trip? {
        trips
            .filter { $0.id != excluding?.id && phase(of: $0, now: now) == .upcoming }
            .compactMap { trip in trip.legs.map(\.arrivalDate).min().map { (trip, $0) } }
            .min { $0.1 < $1.1 }
            .map(\.0)
    }

    static func mostRecentlyCompletedTrip(in trips: [Trip], within days: Int = 7, now: Date = .now) -> Trip? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        return trips
            .compactMap { trip -> (Trip, Date)? in
                guard
                    phase(of: trip, now: now) == .completed,
                    let latestDeparture = trip.legs.map(\.departureDate).max(),
                    latestDeparture >= cutoff
                else {
                    return nil
                }
                return (trip, latestDeparture)
            }
            .max { $0.1 < $1.1 }
            .map(\.0)
    }

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
