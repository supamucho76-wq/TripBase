import SwiftUI

struct CircularProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.accent.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(
                    progress >= 1 ? AppTheme.accent : AppTheme.accent,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
            Text("\(Int((progress * 100).rounded()))%")
                .font(.system(size: size * 0.26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    CircularProgressRing(progress: 0.78)
}
