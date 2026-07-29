import SwiftData
import SwiftUI

struct ForexView: View {
    @Query(sort: \Trip.createdAt) private var trips: [Trip]

    @State private var amountText = "10000"
    @State private var rate: Double?
    @State private var isStale = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    private var allLegs: [TripLeg] {
        trips.flatMap(\.legs)
    }

    private var currentOrNextLeg: TripLeg? {
        TripStatusService.currentLeg(in: allLegs) ?? TripStatusService.nextLeg(in: allLegs)
    }

    private var targetCurrencyCode: String? {
        guard let leg = currentOrNextLeg else { return nil }
        return CountryInfoStore.lookup(leg.countryCode)?.currencyCode
    }

    var body: some View {
        Group {
            if let targetCurrencyCode {
                Form {
                    Section("換算元（日本円）") {
                        TextField("金額", text: $amountText)
                            .keyboardType(.numberPad)
                    }

                    Section(targetCurrencyCode) {
                        if isLoading {
                            ProgressView()
                        } else if let rate {
                            Text(convertedAmountText(rate: rate))
                                .font(.title2.bold())
                            Text("為替レート: 1 JPY ≒ \(rate, specifier: "%.4f") \(targetCurrencyCode)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            if isStale {
                                Text("オフライン — 前回取得時点の情報")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "行程がまだありません",
                    systemImage: "yensign.circle",
                    description: Text("出張先を登録すると、現地通貨への換算ができるようになります。")
                )
            }
        }
        .navigationTitle("為替")
        .task(id: targetCurrencyCode) {
            await loadRate()
        }
    }

    private func convertedAmountText(rate: Double) -> String {
        let amount = Double(amountText) ?? 0
        let converted = amount * rate
        return converted.formatted(.number.precision(.fractionLength(0...2)))
    }

    private func loadRate() async {
        guard let targetCurrencyCode else { return }
        isLoading = true
        errorMessage = nil
        isStale = false

        let result = await APICache.fetch(key: "forex-JPY-\(targetCurrencyCode)") {
            try await ForexAPIClient.fetchRate(to: targetCurrencyCode)
        }
        if let value = result.value {
            rate = value
            isStale = result.isStale
        } else {
            errorMessage = "オフラインか、為替レートを取得できませんでした。"
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        ForexView()
    }
}
