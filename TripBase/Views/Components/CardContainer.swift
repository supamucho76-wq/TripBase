import SwiftUI

struct CardContainer: ViewModifier {
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

extension View {
    func cardStyle(padding: CGFloat = 18) -> some View {
        modifier(CardContainer(padding: padding))
    }
}
