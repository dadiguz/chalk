import SwiftUI

/// Subrayado de gis lima, igual al del ícono: puntos de polvo con grosor que se afina en las puntas.
struct ChalkUnderline: View {
    var color = Color(.lime)

    private static let dots = makeDots()

    var body: some View {
        Canvas { context, size in
            for dot in Self.dots {
                let rect = CGRect(
                    x: dot.x * size.width,
                    y: dot.y * size.height,
                    width: dot.diameter * size.height,
                    height: dot.diameter * size.height
                )
                context.fill(Path(ellipseIn: rect), with: .color(color.opacity(dot.opacity)))
            }
        }
        .drawingGroup()
        .accessibilityHidden(true)
    }

    private struct Dot {
        let x: Double
        let y: Double
        let diameter: Double
        let opacity: Double
    }

    /// Coordenadas normalizadas (0…1) con semilla fija para que siempre se vea igual.
    private static func makeDots() -> [Dot] {
        var generator = SeededGenerator(seed: 42)
        func random(_ range: ClosedRange<Double>) -> Double { Double.random(in: range, using: &generator) }

        let knots = (0..<40).map { _ in random(0...1) }
        func noise(_ t: Double) -> Double {
            let p = t * Double(knots.count - 1)
            let i = Int(p)
            let f = p - Double(i)
            let a = knots[i]
            let b = knots[min(i + 1, knots.count - 1)]
            return a + (b - a) * (f * f * (3 - 2 * f))
        }

        var dots: [Dot] = []
        let count = 5000
        for i in 0..<count {
            let t = Double(i) / Double(count)
            guard random(0...1) < 0.45 + 0.55 * noise(t) else { continue }
            // Alto normalizado: el trazo ocupa ~60% del alto, con curva leve que sube a la derecha.
            let thickness = (0.12 + 0.55 * pow(sin(t * .pi), 0.6) * (1 - 0.35 * t))
            let center = 0.62 - sin(t * .pi) * 0.12 - t * t * 0.35
            dots.append(Dot(
                x: t + random(-0.004...0.004),
                y: center + random(-thickness / 2...thickness / 2),
                diameter: random(0.04...0.1),
                opacity: random(0.35...0.95)
            ))
        }
        return dots
    }
}

/// Generador determinista (LCG) para que el subrayado sea idéntico en cada arranque.
nonisolated struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
