import SwiftUI

struct DocumentsHomeView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "書類機能は準備中です",
                systemImage: "doc.text",
                description: Text("航空券・ホテル予約・パスポートなどをまとめて保存できるようになります。")
            )
            .navigationTitle("書類")
        }
    }
}

#Preview {
    DocumentsHomeView()
}
