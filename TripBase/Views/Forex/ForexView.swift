import SwiftData
import SwiftUI

struct ForexView: View {
    @Query(sort: \Trip.createdAt) private var trips: [Trip]

    @State private var amountText = "10000"
    @State private var forexRate: ForexRate?
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
                        } else if let forexRate {
                            Text(convertedAmountText(rate: forexRate.rate))
                                .font(.title2.bold())
                            Text("為替レート: 1 JPY ≒ \(forexRate.rate, specifier: "%.4f") \(targetCurrencyCode)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            if !forexRate.asOfDate.isEmpty {
                                Text(isStale ? "オフライン — \(forexRate.asOfDate)時点の情報" : "\(forexRate.asOfDate)時点の基準レート（1日1回更新）")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else if let errorMessage {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                Button {
                                    Task { await loadRate() }
                                } label: {
                                    Label("再試行", systemImage: "arrow.clockwise")
                                        .font(.footnote.bold())
                                }
                            }
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
        .contentMargins(.bottom, 90, for: .scrollContent)
        .navigationTitle("為替")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await loadRate() }
                } label: {
                    Label("更新", systemImage: "arrow.clockwise")
                }
                .accessibilityLabel("為替レートを更新する")
            }
        }
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
            forexRate = value
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
