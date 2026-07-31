import SwiftData
import SwiftUI

struct PerDiemView: View {
    @Bindable var trip: Trip

    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Trip> { !$0.isTemplate }, sort: \Trip.createdAt) private var allTrips: [Trip]

    @State private var currencyCode: String
    @State private var dailyRateAmount: Double
    @State private var travelDayRateAmount: Double
    @State private var notes: String

    @State private var jpyRate: ForexRate?
    @State private var isLoadingRate = false
    @State private var rateErrorMessage: String?

    @State private var yearlyRatesToJPY: [String: Double] = [:]

    private enum Field: Hashable {
        case dailyRate
        case travelDayRate
        case currency
        case notes
    }

    @FocusState private var focusedField: Field?

    init(trip: Trip) {
        self.trip = trip
        _currencyCode = State(initialValue: trip.perDiemRule?.currencyCode ?? trip.baseCurrencyCode)
        _dailyRateAmount = State(initialValue: trip.perDiemRule?.dailyRateAmount ?? 0)
        _travelDayRateAmount = State(initialValue: trip.perDiemRule?.travelDayRateAmount ?? 0)
        _notes = State(initialValue: trip.perDiemRule?.notes ?? "")
    }

    private var tripDurationDays: Int {
        TripStatusService.tripDurationDays(of: trip) ?? 0
    }

    private var travelDays: Int {
        PerDiemCalculator.travelDayCount(tripDurationDays: tripDurationDays)
    }

    private var fullDays: Int {
        PerDiemCalculator.fullDayCount(tripDurationDays: tripDurationDays)
    }

    private var total: Double {
        let rule = PerDiemRule(
            currencyCode: currencyCode,
            dailyRateAmount: dailyRateAmount,
            travelDayRateAmount: travelDayRateAmount
        )
        return PerDiemCalculator.total(rule: rule, tripDurationDays: tripDurationDays)
    }

    private var dailyAverage: Double {
        guard tripDurationDays > 0 else { return 0 }
        return total / Double(tripDurationDays)
    }

    private var isJPY: Bool {
        currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "JPY"
    }

    private var totalText: String {
        "\(total.formatted(.number.precision(.fractionLength(0...2)))) \(currencyCode)"
    }

    private func jpyText(for amount: Double) -> String? {
        guard let jpyRate else { return nil }
        let converted = amount * jpyRate.rate
        return "約\(converted.formatted(.number.precision(.fractionLength(0)))) 円"
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: .now)
    }

    private var yearSummary: PerDiemYearSummary {
        PerDiemHistoryService.summary(for: currentYear, trips: allTrips)
    }

    private var jpyYearlyTotal: Double? {
        guard !yearSummary.totalsByCurrency.isEmpty else { return nil }
        return PerDiemHistoryService.jpyTotal(summary: yearSummary, ratesToJPY: yearlyRatesToJPY)
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label("これはあくまで参考値です", systemImage: "info.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.warning)
                    Text("実際の支給額は勤務先の出張旅費規定や給与明細をご確認ください。このアプリは経費精算・承認のためのツールではありません。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if tripDurationDays == 0 {
                Section {
                    Text("行程が未登録のため計算できません。「出張」タブから目的地・日程を登録してください。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("日当（1日あたり）") {
                    HStack {
                        Text("通貨")
                        Spacer()
                        TextField("JPY", text: $currencyCode)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 80)
                            .focused($focusedField, equals: .currency)
                            .onChange(of: currencyCode) { _, _ in save() }
                    }
                    HStack {
                        Text("通常日")
                        Spacer()
                        TextField("0", value: $dailyRateAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .dailyRate)
                            .onChange(of: dailyRateAmount) { _, _ in save() }
                    }
                    HStack {
                        Text("移動日（出発日・帰国日）")
                        Spacer()
                        TextField("0", value: $travelDayRateAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .travelDayRate)
                            .onChange(of: travelDayRateAmount) { _, _ in save() }
                    }
                }

                Section("内訳") {
                    LabeledContent("出張日数", value: "\(tripDurationDays)日")
                    LabeledContent("移動日", value: "\(travelDays)日 × \(travelDayRateAmount.formatted(.number.precision(.fractionLength(0...2)))) \(currencyCode)")
                    LabeledContent("通常日", value: "\(fullDays)日 × \(dailyRateAmount.formatted(.number.precision(.fractionLength(0...2)))) \(currencyCode)")
                }

                Section {
                    VStack(spacing: 6) {
                        Text(totalText)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.accent)
                        if !isJPY {
                            if isLoadingRate {
                                ProgressView()
                            } else if let jpyText = jpyText(for: total) {
                                Text(jpyText)
                                    .font(.title3.bold())
                                    .foregroundStyle(.secondary)
                            } else if let rateErrorMessage {
                                Text(rateErrorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        CopyButton(text: totalText, label: "合計をコピー", systemImage: "doc.on.doc")
                            .font(.footnote)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)

                    if tripDurationDays > 0 {
                        VStack(spacing: 2) {
                            Text("1日平均")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 6) {
                                Text("\(dailyAverage.formatted(.number.precision(.fractionLength(0...2)))) \(currencyCode)/日")
                                    .font(.subheadline.bold())
                                if !isJPY, let jpyAverageText = jpyText(for: dailyAverage) {
                                    Text("(\(jpyAverageText)/日)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                } header: {
                    Text("合計（参考）")
                } footer: {
                    if !isJPY {
                        Text("為替レートは為替タブと同じ基準レート（1日1回更新）を使用しています。")
                    }
                }

                Section {
                    TextField("メモ", text: $notes, axis: .vertical)
                        .focused($focusedField, equals: .notes)
                        .onChange(of: notes) { _, _ in save() }
                }
            }

            if yearSummary.tripCount > 0 {
                Section {
                    ForEach(yearSummary.totalsByCurrency.sorted(by: { $0.key < $1.key }), id: \.key) { currency, amount in
                        LabeledContent(currency, value: amount.formatted(.number.precision(.fractionLength(0...2))))
                    }
                    if let jpyYearlyTotal {
                        LabeledContent("円換算合計") {
                            Text("約\(jpyYearlyTotal.formatted(.number.precision(.fractionLength(0)))) 円")
                                .font(.headline)
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                } header: {
                    Text("\(String(currentYear))年の日当累計（参考）")
                } footer: {
                    Text("\(yearSummary.tripCount)件の出張が対象です。")
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    focusedField = nil
                }
            }
        }
        .navigationTitle("日当計算（参考）")
        .navigationBarTitleDisplayMode(.inline)
        .contentMargins(.bottom, 90, for: .scrollContent)
        .task(id: currencyCode) {
            await loadRate()
        }
        .task(id: yearSummary.totalsByCurrency.keys.sorted().joined(separator: ",")) {
            await loadYearlyRates()
        }
    }

    private func loadYearlyRates() async {
        let currencies = yearSummary.totalsByCurrency.keys.filter { $0.uppercased() != "JPY" }
        for currency in currencies where yearlyRatesToJPY[currency] == nil {
            let result = await APICache.fetch(key: "forex-\(currency)-JPY") {
                try await ForexAPIClient.fetchRate(from: currency, to: "JPY")
            }
            if let value = result.value {
                yearlyRatesToJPY[currency] = value.rate
            }
        }
    }

    private func loadRate() async {
        guard !isJPY else {
            jpyRate = nil
            return
        }
        isLoadingRate = true
        rateErrorMessage = nil
        let code = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let result = await APICache.fetch(key: "forex-\(code)-JPY") {
            try await ForexAPIClient.fetchRate(from: code, to: "JPY")
        }
        if let value = result.value {
            jpyRate = value
        } else {
            rateErrorMessage = "為替レートを取得できませんでした"
        }
        isLoadingRate = false
    }

    private func save() {
        let rule = trip.perDiemRule ?? PerDiemRule(trip: trip)
        rule.currencyCode = currencyCode
        rule.dailyRateAmount = dailyRateAmount
        rule.travelDayRateAmount = travelDayRateAmount
        rule.notes = notes
        rule.updatedAt = .now

        if trip.perDiemRule == nil {
            trip.perDiemRule = rule
        }

        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        PerDiemView(trip: Trip(name: "Preview"))
    }
}
