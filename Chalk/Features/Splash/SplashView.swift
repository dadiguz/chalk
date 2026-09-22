import SwiftUI

/// Splash: "Chalk" se escribe a mano sobre un pizarrón y luego se desvanece.
struct SplashView: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var layout: HandwritingLayout?
    @State private var progress = 0.0
    @State private var isLeaving = false
    @State private var isComplete = false
    @State private var availableWidth = 0.0

    private let fontSize = 68.0
    private let drawDuration = 1.8

    var body: some View {
        ZStack {
            Color(.chalkboard)
                .ignoresSafeArea()

            if let layout {
                ZStack(alignment: .topLeading) {
                    layout.textPath
                        .fill(.white.opacity(0.95))
                        .mask {
                            HandwritingMask(strokes: layout.strokes, progress: progress)
                                .stroke(.white, style: StrokeStyle(lineWidth: layout.brushWidth, lineCap: .round, lineJoin: .round))
                        }
                    // Asegura que la palabra quede completa aunque algún trazo no cubra un borde.
                    layout.textPath
                        .fill(.white.opacity(isComplete ? 0.95 : 0))
                }
                .frame(width: layout.size.width, height: layout.size.height, alignment: .topLeading)
                .shadow(color: .white.opacity(0.25), radius: 6)
                .scaleEffect(fitScale(for: layout) * (isLeaving ? 1.06 : 1))
            }
        }
        .onGeometryChange(for: Double.self) { $0.size.width } action: { availableWidth = $0 }
        .opacity(isLeaving ? 0 : 1)
        .contentShape(.rect)
        .onTapGesture { finish() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Chalk")
        .task { await run() }
    }

    private func run() async {
        let built = await HandwritingLayout.make(text: "Chalk", fontName: FontRegistry.brandFontNameOrFallback, fontSize: fontSize)
        layout = built
        if reduceMotion {
            progress = 1
            isComplete = true
            try? await Task.sleep(for: .seconds(0.6))
        } else {
            withAnimation(.easeInOut(duration: drawDuration)) { progress = 1 }
            try? await Task.sleep(for: .seconds(drawDuration))
            withAnimation(.easeIn(duration: 0.2)) { isComplete = true }
            try? await Task.sleep(for: .seconds(0.5))
        }
        finish()
    }

    /// Reduce el texto si no cabe con 32 pt de margen por lado.
    private func fitScale(for layout: HandwritingLayout) -> Double {
        guard availableWidth > 0 else { return 1 }
        return min(1, (availableWidth - 64) / layout.size.width)
    }

    private func finish() {
        guard !isLeaving else { return }
        withAnimation(.easeOut(duration: 0.35)) { isLeaving = true } completion: {
            onFinish()
        }
    }
}
