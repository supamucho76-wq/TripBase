import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \Trip.createdAt) private var trips: [Trip]

    private var allLegs: [TripLeg] {
        trips.flatMap(\.legs)
    }

    private var currentLeg: TripLeg? {
        TripStatusService.currentLeg(in: allLegs)
    }

    private var nextLeg: TripLeg? {
        TripStatusService.nextLeg(in: allLegs)
    }

    private var upcomingLegs: [TripLeg] {
        TripStatusService.upcomingLegs(in: allLegs, excluding: currentLeg)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header

                    if let currentLeg {
                        currentStatusCard(currentLeg)
                    } else if let nextLeg {
                        nextDestinationCard(nextLeg)
                    } else {
                        ContentUnavailableView(
                            "出張の予定がありません",
                            systemImage: "airplane",
                            description: Text("「出張」タブから行程を追加してください。")
                        )
                    }

                    if !upcomingLegs.isEmpty {
                        upcomingList
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("出張コンパス")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date.now.formatted(.dateTime.month().day().weekday(.wide)))
                    .font(.title2.bold())
            }
            Spacer()
            Image(systemName: "airplane.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(AppTheme.accent)
        }
    }

    private func currentStatusCard(_ leg: TripLeg) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                StatusBadge(title: "出張中", color: AppTheme.accent)
                Spacer()
                Text("残り\(TripStatusService.nightsRemaining(for: leg))泊")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(leg.cityName)
                    .font(.title2.bold())
                Text(leg.countryCode)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            if !leg.hotelName.isEmpty {
                Label(leg.hotelName, systemImage: "bed.double")
                    .foregroundStyle(.secondary)
            }
            Text("\(AppDateFormatter.date.string(from: leg.arrivalDate)) 〜 \(AppDateFormatter.date.string(from: leg.departureDate))")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(AppTheme.accent.opacity(0.11))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    private func nextDestinationCard(_ leg: TripLeg) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("次の出張", systemImage: "arrow.right.circle")
                .font(.headline)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(leg.cityName)
                    .font(.title3.bold())
                Text(leg.countryCode)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            Text(AppDateFormatter.date.string(from: leg.arrivalDate) + " 出発")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var upcomingList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今後の行程")
                .font(.headline)
            ForEach(upcomingLegs) { leg in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(leg.cityName)（\(leg.countryCode)）")
                            .font(.subheadline.bold())
                        if !leg.hotelName.isEmpty {
                            Text(leg.hotelName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(AppDateFormatter.shortDate.string(from: leg.arrivalDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
        .cardStyle()
    }
}

#Preview {
    HomeView()
}
