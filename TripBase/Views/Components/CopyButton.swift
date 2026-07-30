import SwiftUI

/// A copy-to-clipboard button that briefly confirms itself ("コピーしました")
/// instead of copying silently with no feedback.
struct CopyButton: View {
    let text: String
    let label: String
    let systemImage: String

    @State private var justCopied = false

    var body: some View {
        Button {
            UIPasteboard.general.string = text
            HapticsService.lightImpact()
            justCopied = true
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                justCopied = false
            }
        } label: {
            Label(justCopied ? "コピーしました" : label, systemImage: justCopied ? "checkmark" : systemImage)
                .foregroundStyle(justCopied ? AppTheme.accent : .primary)
        }
        .animation(.easeOut(duration: 0.15), value: justCopied)
        .accessibilityLabel(justCopied ? "コピーしました" : label)
    }
}
