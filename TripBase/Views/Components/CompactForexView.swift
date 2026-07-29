import SwiftUI

struct CompactForexView: View {
    let leg: TripLeg

    @State private var forexRate: ForexRate?
    @State private var isStale = false
    @State private var errorMessage: String?

    private var targetCurrencyCode: String? {
        CountryInfoStore.lookup(leg.countryCode)?.currencyCode
    }

    var body: some View {
        Group {
            if let targetCurrencyCode {
                VStack(alignment: .leading, spacing: 4) {
                    Label("為替（1万円）", systemImage: "yensign.circle")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    if let forexRate {
                        Text("\((10_000 * forexRate.rate).formatted(.number.precision(.fractionLength(0...2)))) \(targetCurrencyCode)")
                            .font(.title3.bold())
                        if !forexRate.asOfDate.isEmpty {
                            Text(isStale ? "オフライン — \(forexRate.asOfDate)時点" : "\(forexRate.asOfDate)時点の基準レート")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        ProgressView()
                    }
                }
                .task(id: targetCurrencyCode) {
                    await load(targetCurrencyCode: targetCurrencyCode)
                }
            }
        }
    }

    private func load(targetCurrencyCode: String) async {
        let result = await APICache.fetch(key: "forex-JPY-\(targetCurrencyCode)") {
            try await ForexAPIClient.fetchRate(to: targetCurrencyCode)
        }
        if let value = result.value {
            forexRate = value
            isStale = result.isStale
        } else {
            errorMessage = "為替レートを取得できませんでした"
        }
    }
}
