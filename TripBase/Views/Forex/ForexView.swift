import SwiftUI

struct ForexView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "為替換算は準備中です",
                systemImage: "yensign.circle",
                description: Text("日当や経費を現地通貨に換算できるようになります。")
            )
            .navigationTitle("為替")
        }
    }
}

#Preview {
    ForexView()
}
