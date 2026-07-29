import SwiftUI

struct CardContainer: ViewModifier {
    var padding: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.separator.opacity(0.5), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
}

extension View {
    func cardStyle(padding: CGFloat = 14) -> some View {
        modifier(CardContainer(padding: padding))
    }
}
