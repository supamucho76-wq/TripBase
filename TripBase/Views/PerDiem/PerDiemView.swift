import SwiftData
import SwiftUI

struct PerDiemView: View {
    @Bindable var trip: Trip

    @Environment(\.modelContext) private var modelContext

    @State private var currencyCode: String
    @State private var dailyRateAmount: Double
    @State private var travelDayRateAmount: Double
    @State private var notes: String

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
                            .onChange(of: currencyCode) { _, _ in save() }
                    }
                    HStack {
                        Text("通常日")
                        Spacer()
                        TextField("0", value: $dailyRateAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: dailyRateAmount) { _, _ in save() }
                    }
                    HStack {
                        Text("移動日（出発日・帰国日）")
                        Spacer()
                        TextField("0", value: $travelDayRateAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: travelDayRateAmount) { _, _ in save() }
                    }
                }

                Section("内訳") {
                    LabeledContent("出張日数", value: "\(tripDurationDays)日")
                    LabeledContent("移動日", value: "\(travelDays)日 × \(travelDayRateAmount.formatted(.number.precision(.fractionLength(0...2)))) \(currencyCode)")
                    LabeledContent("通常日", value: "\(fullDays)日 × \(dailyRateAmount.formatted(.number.precision(.fractionLength(0...2)))) \(currencyCode)")
                }

                Section("合計（参考）") {
                    Text("\(total.formatted(.number.precision(.fractionLength(0...2)))) \(currencyCode)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }

                Section {
                    TextField("メモ", text: $notes, axis: .vertical)
                        .onChange(of: notes) { _, _ in save() }
                }
            }
        }
        .navigationTitle("日当計算（参考）")
        .navigationBarTitleDisplayMode(.inline)
        .contentMargins(.bottom, 90, for: .scrollContent)
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
