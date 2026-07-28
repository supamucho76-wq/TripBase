import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.05, green: 0.45, blue: 0.34)
    static let warning = Color(red: 0.88, green: 0.45, blue: 0.08)
    static let danger = Color(red: 0.78, green: 0.12, blue: 0.12)
    static let background = Color(.systemGroupedBackground)
}

struct LargeActionButtonStyle: ButtonStyle {
    var color: Color = AppTheme.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(color.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct StatusBadge: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.caption.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
