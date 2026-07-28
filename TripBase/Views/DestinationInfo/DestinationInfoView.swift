import SwiftUI

struct DestinationInfoView: View {
    let leg: TripLeg

    private var countryInfo: CountryInfo? {
        CountryInfoStore.lookup(leg.countryCode)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let countryInfo {
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
        .background(AppTheme.background)
        .navigationTitle("\(CountryInfoStore.displayName(for: leg.countryCode))の情報")
        .navigationBarTitleDisplayMode(.inline)
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
