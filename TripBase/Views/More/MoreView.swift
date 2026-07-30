import SwiftData
import SwiftUI

struct MoreView: View {
    @Query(sort: \Trip.createdAt) private var trips: [Trip]

    private var allLegs: [TripLeg] {
        trips.flatMap(\.legs)
    }

    private var currentOrNextLeg: TripLeg? {
        TripStatusService.currentLeg(in: allLegs) ?? TripStatusService.nextLeg(in: allLegs)
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    LazyVGrid(columns: columns, spacing: 14) {
                        NavigationLink { WeatherView() } label: {
                            toolTile(title: "天気", systemImage: "cloud.sun.fill")
                        }
                        NavigationLink { ForexView() } label: {
                            toolTile(title: "為替", systemImage: "yensign.circle.fill")
                        }
                        NavigationLink { TimezoneOverviewView() } label: {
                            toolTile(title: "時差", systemImage: "clock.fill")
                        }
                        NavigationLink {
                            if let leg = currentOrNextLeg {
                                DestinationInfoView(leg: leg)
                            } else {
                                ContentUnavailableView(
                                    "行程がまだありません",
                                    systemImage: "mappin.and.ellipse",
                                    description: Text("出張先を登録すると、現地情報が使えるようになります。")
                                )
                            }
                        } label: {
                            toolTile(title: "現地情報", systemImage: "mappin.and.ellipse")
                        }
                    }
                    .pressableCardStyle()

                    NavigationLink {
                        ContentUnavailableView(
                            "翻訳機能は準備中です",
                            systemImage: "text.bubble",
                            description: Text("出張先でよく使う定型文を保存できるようになります。")
                        )
                        .navigationTitle("翻訳")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        comingSoonTile(title: "翻訳", systemImage: "text.bubble")
                    }
                    .pressableCardStyle()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("管理")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        NavigationLink {
                            TripListView(initialStatusFilter: .completed)
                        } label: {
                            HStack {
                                Label("出張履歴", systemImage: "clock.arrow.circlepath")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .foregroundStyle(.primary)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle(padding: 0)
                        }
                        .pressableCardStyle()
                    }
                }
                .padding()
            }
            .contentMargins(.bottom, 90, for: .scrollContent)
            .background(AppTheme.background)
            .navigationTitle("ツール")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func toolTile(title: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 26))
                .foregroundStyle(AppTheme.accent)
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .cardStyle(padding: 0)
    }

    private func comingSoonTile(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            Spacer()
            Text("準備中")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.12))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(14)
        .background(.background.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .foregroundStyle(.separator)
        }
    }
}

#Preview {
    MoreView()
}
