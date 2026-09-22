import SwiftUI

/// Trazos dibujados hasta `progress` (0…1), con una pausa corta entre trazos como al levantar el gis.
struct HandwritingMask: Shape {
    let strokes: [[CGPoint]]
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private var lengths: [Double] {
        strokes.map { stroke in
            zip(stroke, stroke.dropFirst()).reduce(0) { $0 + hypot($1.1.x - $1.0.x, $1.1.y - $1.0.y) }
        }
    }

    func path(in rect: CGRect) -> Path {
        let lengths = lengths
        let penLift = (lengths.reduce(0, +) / Double(max(lengths.count, 1))) * 0.25
        let total = lengths.reduce(0, +) + penLift * Double(max(strokes.count - 1, 0))
        var remaining = progress * total
        var path = Path()

        for (stroke, length) in zip(strokes, lengths) {
            guard remaining > 0, let first = stroke.first else { break }
            path.move(to: first)
            if remaining >= length {
                stroke.dropFirst().forEach { path.addLine(to: $0) }
            } else {
                var drawn = 0.0
                for (a, b) in zip(stroke, stroke.dropFirst()) {
                    let segment = hypot(b.x - a.x, b.y - a.y)
                    if drawn + segment >= remaining {
                        let t = segment > 0 ? (remaining - drawn) / segment : 0
                        path.addLine(to: CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))
                        break
                    }
                    drawn += segment
                    path.addLine(to: b)
                }
            }
            remaining -= length + penLift
        }
        return path
    }
}
