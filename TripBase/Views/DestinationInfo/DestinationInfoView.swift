import SwiftData
import SwiftUI

struct DestinationInfoView: View {
    @Bindable var leg: TripLeg

    @Environment(\.modelContext) private var modelContext
    @State private var holidays: [PublicHoliday] = []
    @State private var holidaysErrorMessage: String?
    @State private var isLoadingHolidays = false
    @State private var isHolidaysStale = false
    @State private var isAddPlacePresented = false
    @State private var placePendingDelete: LocalPlace?

    private var countryInfo: CountryInfo? {
        CountryInfoStore.lookup(leg.countryCode)
    }

    private var sortedPlaces: [LocalPlace] {
        leg.localPlaces.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hotelToolsSection
                localPlacesSection

                if let countryInfo {
                    timezoneSection(countryInfo)
                    holidaySection
                    plugVoltageSection(countryInfo)
                    tippingSection(countryInfo)
                    packingSection(countryInfo)
                    safetySection(countryInfo)
                    embassySection(countryInfo)
                } else {
                    ContentUnavailableView(
                        "この国の情報は準備中です",
                        systemImage: "questionmark.circle",
                        description: Text("国コード「\(leg.countryCode)」のデータはまだ登録されていません。")
                    )
                }
            }
            .padding()
        }
        .contentMargins(.bottom, 90, for: .scrollContent)
        .background(AppTheme.background)
        .navigationTitle("\(CountryInfoStore.displayName(for: leg.countryCode))の情報")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: leg.countryCode) {
            await loadHolidays()
        }
        .sheet(isPresented: $isAddPlacePresented) {
            LocalPlaceEditorView(leg: leg)
        }
        .alert(
            "この場所を削除しますか？",
            isPresented: Binding(
                get: { placePendingDelete != nil },
                set: { isPresented in
                    if !isPresented { placePendingDelete = nil }
                }
            )
        ) {
            Button("削除", role: .destructive) {
                if let place = placePendingDelete {
                    modelContext.delete(place)
                }
                placePendingDelete = nil
            }
            Button("キャンセル", role: .cancel) {
                placePendingDelete = nil
            }
        } message: {
            Text("削除すると元に戻せません。")
        }
    }

    private func mapsURL(for address: String) -> URL? {
        guard !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        var components = URLComponents(string: "https://www.google.com/maps/search/")
        components?.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "query", value: address)
        ]
        return components?.url
    }

    private var hotelToolsSection: some View {
        Group {
            if !leg.hotelName.isEmpty || !leg.hotelAddress.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("ホテル", systemImage: "bed.double")
                        .font(.headline)
                    if !leg.hotelName.isEmpty {
                        Text(leg.hotelName)
                            .font(.subheadline.bold())
                    }
                    if !leg.hotelAddress.isEmpty {
                        Text(leg.hotelAddress)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if !leg.hotelAddressLocalLanguage.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("現地語の住所（タクシーなどで見せる用）")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(leg.hotelAddressLocalLanguage)
                                .font(.footnote.bold())
                        }
                    }
                    HStack(spacing: 16) {
                        if !leg.hotelAddress.isEmpty {
                            CopyButton(text: leg.hotelAddress, label: "住所をコピー", systemImage: "doc.on.doc")
                            if let url = mapsURL(for: leg.hotelAddress) {
                                Link(destination: url) {
                                    Label("地図で開く", systemImage: "map")
                                }
                            }
                        }
                        if !leg.hotelAddressLocalLanguage.isEmpty {
                            CopyButton(text: leg.hotelAddressLocalLanguage, label: "現地語住所をコピー", systemImage: "doc.on.doc")
                        }
                        if !leg.hotelBookingReference.isEmpty {
                            CopyButton(text: leg.hotelBookingReference, label: "予約番号をコピー", systemImage: "number")
                        }
                    }
                    .font(.footnote)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
        }
    }

    private var localPlacesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("よく使う場所", systemImage: "mappin.and.ellipse")
                    .font(.headline)
                Spacer()
                Button {
                    isAddPlacePresented = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("よく使う場所を追加する")
            }
            if sortedPlaces.isEmpty {
                Text("勤務先・空港・タクシー行き先・病院・コンビニなどを登録しておくと、出張中すぐに呼び出せます。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedPlaces) { place in
                    localPlaceRow(place)
                    if place.id != sortedPlaces.last?.id {
                        Divider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func localPlaceRow(_ place: LocalPlace) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(place.name, systemImage: place.category.systemImage)
                    .font(.subheadline.bold())
                Spacer()
                Text(place.category.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if !place.address.isEmpty {
                Text(place.address)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                if !place.address.isEmpty {
                    CopyButton(text: place.address, label: "住所をコピー", systemImage: "doc.on.doc")
                    if let url = mapsURL(for: place.address) {
                        Link(destination: url) {
                            Label("地図で開く", systemImage: "map")
                        }
                    }
                }
                if !place.phone.isEmpty, let phoneURL = URL(string: "tel://\(place.phone.filter { $0.isNumber || $0 == "+" })") {
                    Link(destination: phoneURL) {
                        Label("電話", systemImage: "phone")
                    }
                }
                Spacer()
                Button(role: .destructive) {
                    placePendingDelete = place
                } label: {
                    Image(systemName: "trash")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("\(place.name)を削除")
            }
            .font(.footnote)
        }
        .padding(.vertical, 2)
    }

    private var holidaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("現地の祝日", systemImage: "calendar")
                    .font(.headline)
                Spacer()
                if isLoadingHolidays {
                    ProgressView()
                }
            }
            if !holidays.isEmpty {
                ForEach(upcomingHolidays) { holiday in
                    HStack {
                        Text(holiday.date)
                        Spacer()
                        Text(holiday.localName)
                            .foregroundStyle(.secondary)
                    }
                    .font(.footnote)
                }
                if isHolidaysStale {
                    Text("オフライン — 前回取得時点の情報")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else if let holidaysErrorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text(holidaysErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button {
                        Task { await loadHolidays() }
                    } label: {
                        Label("再試行", systemImage: "arrow.clockwise")
                            .font(.footnote.bold())
                    }
                }
            } else if !isLoadingHolidays {
                Text("今年の祝日データはありません。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var upcomingHolidays: [PublicHoliday] {
        Array(holidays.prefix(5))
    }

    private func loadHolidays() async {
        isLoadingHolidays = true
        holidaysErrorMessage = nil
        isHolidaysStale = false
        let year = Calendar.current.component(.year, from: .now)
        let countryCode = leg.countryCode

        let result = await APICache.fetch(key: "holidays-\(countryCode)-\(year)") {
            try await HolidayAPIClient.fetchHolidays(countryCode: countryCode, year: year)
        }
        if let value = result.value {
            holidays = value
            isHolidaysStale = result.isStale
        } else {
            holidaysErrorMessage = "オフラインか、祝日情報を取得できませんでした。"
        }
        isLoadingHolidays = false
    }

    private func timezoneSection(_ info: CountryInfo) -> some View {
        let diff = TimezoneService.hourDifference(destinationIdentifier: info.timeZoneIdentifier)
        let currentTime = TimezoneService.currentTime(destinationIdentifier: info.timeZoneIdentifier)

        return VStack(alignment: .leading, spacing: 8) {
            Label("時差", systemImage: "clock")
                .font(.headline)
            if let currentTime {
                Text("現地時刻: \(currentTime)")
            }
            if let diff {
                Text(diff == 0 ? "日本と時差はありません" : "日本より\(diff > 0 ? "\(diff)時間進んでいます" : "\(-diff)時間遅れています")")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func plugVoltageSection(_ info: CountryInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("電源プラグ・電圧", systemImage: "poweroutlet.type.b")
                .font(.headline)
            Text("プラグ形状: \(info.plugTypes.joined(separator: " / "))タイプ")
            Text("電圧: \(info.voltage)V（\(info.frequencyHz)Hz）")
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func tippingSection(_ info: CountryInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("チップ・マナー", systemImage: "hand.raised")
                .font(.headline)
            Text(info.tippingNote)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func packingSection(_ info: CountryInfo) -> some View {
        Group {
            if !info.packingAddenda.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("持ち物リスト（追加分）", systemImage: "checklist")
                        .font(.headline)
                    ForEach(info.packingAddenda, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle")
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
        }
    }

    private func safetySection(_ info: CountryInfo) -> some View {
        Group {
            if let urlString = info.mofaSafetyURL, let url = URL(string: urlString) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("海外安全情報", systemImage: "exclamationmark.shield")
                        .font(.headline)
                    Link("外務省 海外安全ホームページを開く", destination: url)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
        }
    }

    private func embassySection(_ info: CountryInfo) -> some View {
        Group {
            if let embassy = info.embassy {
                VStack(alignment: .leading, spacing: 8) {
                    Label("日本大使館・領事館", systemImage: "building.columns")
                        .font(.headline)
                    Text(embassy.name)
                        .font(.subheadline.bold())
                    Text(embassy.address)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let phoneURL = URL(string: "tel://\(embassy.phone.filter { $0.isNumber || $0 == "+" })") {
                        Link(embassy.phone, destination: phoneURL)
                    } else {
                        Text(embassy.phone)
                    }
                    if let websiteString = embassy.website, let websiteURL = URL(string: websiteString) {
                        Link("公式サイトを開く", destination: websiteURL)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
        }
    }
}

#Preview {
    NavigationStack {
        DestinationInfoView(
            leg: TripLeg(
                countryCode: "FR",
                cityName: "パリ",
                arrivalDate: .now,
                departureDate: .now.addingTimeInterval(3 * 86_400),
                orderIndex: 0
            )
        )
    }
}
