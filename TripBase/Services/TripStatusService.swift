import Foundation

enum TripPhase {
    case noItinerary
    case upcoming
    case inProgress
    case completed
}

enum TripStatusService {
    /// Computed from the trip's own legs rather than stored, so editing dates
    /// can never leave a stale status behind. Compares whole calendar days
    /// (arrival day 00:00 through departure day 23:59:59 in the device's
    /// current calendar/time zone) rather than raw Date instants, so a trip
    /// stays "upcoming" all the way through the night before arrival and
    /// "inProgress" for the entirety of its departure day, regardless of
    /// what time of day the arrival/departure Date values happen to carry.
    static func phase(of trip: Trip, now: Date = .now, calendar: Calendar = .current) -> TripPhase {
        guard !trip.legs.isEmpty else { return .noItinerary }
        guard
            let earliestArrival = trip.legs.map(\.arrivalDate).min(),
            let latestDeparture = trip.legs.map(\.departureDate).max()
        else {
            return .noItinerary
        }
        let tripStart = calendar.startOfDay(for: earliestArrival)
        guard let tripEndExclusive = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: latestDeparture)) else {
            return .inProgress
        }
        if now < tripStart { return .upcoming }
        if now >= tripEndExclusive { return .completed }
        return .inProgress
    }

    /// Whole-day count from `now` to `date`, both floored to the start of
    /// their calendar day first so "tomorrow" always reads as 1 regardless
    /// of the current time of day.
    static func daysUntil(_ date: Date, from now: Date = .now, calendar: Calendar = .current) -> Int {
        let startOfNow = calendar.startOfDay(for: now)
        let startOfDate = calendar.startOfDay(for: date)
        return max(0, calendar.dateComponents([.day], from: startOfNow, to: startOfDate).day ?? 0)
    }

    static func daysUntilDeparture(of trip: Trip, now: Date = .now, calendar: Calendar = .current) -> Int? {
        trip.legs.map(\.arrivalDate).min().map { daysUntil($0, from: now, calendar: calendar) }
    }

    static func daysUntilReturn(of trip: Trip, now: Date = .now, calendar: Calendar = .current) -> Int? {
        trip.legs.map(\.departureDate).max().map { daysUntil($0, from: now, calendar: calendar) }
    }

    /// Which day of the trip `now` falls on (arrival day = day 1). `nil` if
    /// the trip hasn't started yet or has no legs.
    static func dayNumber(of trip: Trip, now: Date = .now, calendar: Calendar = .current) -> Int? {
        guard let firstArrival = trip.legs.map(\.arrivalDate).min() else { return nil }
        let startOfArrival = calendar.startOfDay(for: firstArrival)
        let startOfNow = calendar.startOfDay(for: now)
        guard startOfNow >= startOfArrival else { return nil }
        let daysSinceStart = calendar.dateComponents([.day], from: startOfArrival, to: startOfNow).day ?? 0
        return daysSinceStart + 1
    }

    /// Total planned length of the trip in days, inclusive of both the
    /// arrival and departure days (e.g. arriving and departing the same day
    /// is a 1-day trip).
    static func tripDurationDays(of trip: Trip, calendar: Calendar = .current) -> Int? {
        guard
            let firstArrival = trip.legs.map(\.arrivalDate).min(),
            let lastDeparture = trip.legs.map(\.departureDate).max()
        else {
            return nil
        }
        let start = calendar.startOfDay(for: firstArrival)
        let end = calendar.startOfDay(for: lastDeparture)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return days + 1
    }

    static func totalNights(of trip: Trip, calendar: Calendar = .current) -> Int? {
        tripDurationDays(of: trip, calendar: calendar).map { max(0, $0 - 1) }
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
