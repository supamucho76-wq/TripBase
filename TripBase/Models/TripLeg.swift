import Foundation
import SwiftData

@Model
final class TripLeg {
    var id: UUID
    var countryCode: String
    var cityName: String
    var weatherSearchName: String = ""
    var arrivalDate: Date
    var departureDate: Date
    var hotelName: String
    var hotelAddress: String
    var hotelBookingReference: String
    var hotelNotes: String
    var visaStatusRawValue: String
    var visaNotes: String
    var transportNote: String
    var orderIndex: Int
    var createdAt: Date
    var updatedAt: Date

    var trip: Trip?

    @Relationship(deleteRule: .cascade, inverse: \LocalPlace.tripLeg)
    var localPlaces: [LocalPlace] = []

    var visaStatus: VisaStatus {
        get { VisaStatus(rawValue: visaStatusRawValue) ?? .notRequired }
        set { visaStatusRawValue = newValue.rawValue }
    }

    var weatherQueryName: String {
        weatherSearchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? cityName
            : weatherSearchName
    }

    var nightsCount: Int {
        max(0, Calendar.current.dateComponents([.day], from: arrivalDate, to: departureDate).day ?? 0)
    }

    init(
        id: UUID = UUID(),
        countryCode: String,
        cityName: String,
        arrivalDate: Date,
        departureDate: Date,
        orderIndex: Int,
        trip: Trip? = nil
    ) {
        self.id = id
        self.countryCode = countryCode
        self.cityName = cityName
        self.weatherSearchName = ""
        self.arrivalDate = arrivalDate
        self.departureDate = departureDate
        self.hotelName = ""
        self.hotelAddress = ""
        self.hotelBookingReference = ""
        self.hotelNotes = ""
        self.visaStatusRawValue = VisaStatus.notRequired.rawValue
        self.visaNotes = ""
        self.transportNote = ""
        self.orderIndex = orderIndex
        self.createdAt = .now
        self.updatedAt = .now
        self.trip = trip
        self.localPlaces = []
    }
}
