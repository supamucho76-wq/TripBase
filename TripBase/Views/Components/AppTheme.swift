import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.05, green: 0.45, blue: 0.34)
    static let warning = Color(red: 0.88, green: 0.45, blue: 0.08)
    static let danger = Color(red: 0.78, green: 0.12, blue: 0.12)
    static let background = Color(.systemGroupedBackground)

    // Shared so every hand-rolled card (accent-tinted highlight cards that
    // can't just use .cardStyle()) matches CardContainer's plain-card look.
    static let cardCornerRadius: CGFloat = 18
    static let cardShadowColor = Color.black.opacity(0.04)
    static let cardShadowRadius: CGFloat = 6
    static let cardShadowY: CGFloat = 2
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

/// For custom tappable cards (NavigationLink/Button wrapping a whole card)
/// that would otherwise show zero visual feedback under .buttonStyle(.plain).
/// Dims and slightly shrinks the card while pressed.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func pressableCardStyle() -> some View {
        buttonStyle(PressableCardStyle())
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
