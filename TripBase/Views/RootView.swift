import SwiftUI

struct RootView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "airplane")
                .font(.system(size: 40))
            Text("出張コンパス")
                .font(.title2.bold())
            Text("TripBase — scaffolding phase")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    RootView()
}
