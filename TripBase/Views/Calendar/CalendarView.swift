import SwiftUI

struct CalendarView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "カレンダーは準備中です",
                systemImage: "calendar",
                description: Text("出張・行程をまとめて確認できるようになります。")
            )
            .navigationTitle("カレンダー")
        }
    }
}

#Preview {
    CalendarView()
}
