import SwiftUI

struct CardContainer: ViewModifier {
    var padding: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .stroke(.separator.opacity(0.5), lineWidth: 0.5)
            }
            .shadow(color: AppTheme.cardShadowColor, radius: AppTheme.cardShadowRadius, y: AppTheme.cardShadowY)
    }
}

extension View {
    func cardStyle(padding: CGFloat = 14) -> some View {
        modifier(CardContainer(padding: padding))
    }
}
