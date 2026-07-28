import SwiftUI

struct WeatherView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "天気情報は準備中です",
                systemImage: "cloud.sun",
                description: Text("行き先の天気をここで確認できるようになります。")
            )
            .navigationTitle("天気")
        }
    }
}

#Preview {
    WeatherView()
}
