import Foundation
import SwiftData

/// Deep-copies a Trip - legs, packing list, documents, tasks, notes, and
/// per-diem rates - resetting anything that's specific to a single real
/// occurrence of the trip (check marks, confirmed flags, booking
/// references, attachments, visa status) so the copy starts clean.
enum TripDuplicationService {
    @discardableResult
    static func duplicate(source: Trip, asTemplate: Bool, in context: ModelContext) -> Trip {
        let newTrip = Trip(
            name: asTemplate ? "\(source.name)（テンプレート）" : "\(source.name)のコピー",
            purpose: source.purpose,
            baseCurrencyCode: source.baseCurrencyCode,
            isTemplate: asTemplate
        )
        context.insert(newTrip)

        for (index, leg) in source.legs.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
            let newLeg = TripLeg(
                countryCode: leg.countryCode,
                cityName: leg.cityName,
                arrivalDate: leg.arrivalDate,
                departureDate: leg.departureDate,
                orderIndex: index,
                trip: newTrip
            )
            newLeg.weatherSearchName = leg.weatherSearchName
            newLeg.hotelName = leg.hotelName
            newLeg.hotelAddress = leg.hotelAddress
            newLeg.hotelAddressLocalLanguage = leg.hotelAddressLocalLanguage
            // Booking reference and visa status are specific to one real
            // trip's reservation - don't carry them into the copy.
            newLeg.hotelNotes = leg.hotelNotes
            newLeg.transportNote = ""
            newTrip.legs.append(newLeg)
        }

        for (index, item) in source.packingItems.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
            let newItem = PackingItem(
                trip: newTrip,
                name: item.name,
                category: item.category,
                isChecked: false,
                orderIndex: index
            )
            newTrip.packingItems.append(newItem)
        }

        for (index, document) in source.documents.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated() {
            let newDocument = TripDocument(
                trip: newTrip,
                name: document.name,
                category: document.category,
                // Reference numbers/expiry dates/attachments are tied to one
                // real booking - don't carry them into the copy.
                isConfirmed: false,
                orderIndex: index
            )
            newTrip.documents.append(newDocument)
        }

        for task in source.tasks {
            let newTask = TripTask(trip: newTrip, title: task.title, phase: task.phase, isDone: false)
            newTrip.tasks.append(newTask)
        }

        if let sourceRule = source.perDiemRule {
            let newRule = PerDiemRule(
                trip: newTrip,
                currencyCode: sourceRule.currencyCode,
                dailyRateAmount: sourceRule.dailyRateAmount,
                travelDayRateAmount: sourceRule.travelDayRateAmount
            )
            newTrip.perDiemRule = newRule
        }

        return newTrip
    }
}
