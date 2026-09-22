import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let label: String
    var valueText: String?
    var tint: Color = Color(.lime)

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 7)
                Circle()
                    .trim(from: 0, to: clamped)
                    .stroke(tint, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.smooth, value: clamped)
                Text(valueText ?? clamped.formatted(.percent.precision(.fractionLength(0))))
                    .font(.caption.bold())
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
            }
            .frame(width: 60, height: 60)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(valueText ?? clamped.formatted(.percent.precision(.fractionLength(0))))
    }
}
