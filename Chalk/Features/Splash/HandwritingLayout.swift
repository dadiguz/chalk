import CoreText
import SwiftUI

/// Texto listo para animarse como escritura a mano: el relleno real del texto y los trazos
/// (esqueletos en orden de escritura) que lo van revelando.
nonisolated struct HandwritingLayout: Sendable {
    let textPath: Path
    let strokes: [[CGPoint]]
    let brushWidth: Double
    let size: CGSize

    /// Construye el layout con el enfoque de Tegaki: rasterizar cada glifo, esqueletizarlo con
    /// Zhang-Suen y recorrer el esqueleto de arriba hacia abajo.
    @concurrent
    static func make(text: String, fontName: String, fontSize: Double) async -> HandwritingLayout {
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        let ascent = CTFontGetAscent(font)
        let attributed = NSAttributedString(string: text, attributes: [kCTFontAttributeName as NSAttributedString.Key: font])
        let line = CTLineCreateWithAttributedString(attributed)

        // Glifos en espacio de pantalla (y hacia abajo, línea base en `ascent`).
        var glyphPaths: [CGPath] = []
        for run in (CTLineGetGlyphRuns(line) as? [CTRun]) ?? [] {
            let count = CTRunGetGlyphCount(run)
            var glyphs = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: count), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: count), &positions)
            for (glyph, position) in zip(glyphs, positions) {
                var transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: position.x, ty: ascent - position.y)
                if let path = CTFontCreatePathForGlyph(font, glyph, &transform), !path.boundingBoxOfPath.isEmpty {
                    glyphPaths.append(path)
                }
            }
        }

        let combined = CGMutablePath()
        glyphPaths.forEach { combined.addPath($0) }
        let bounds = combined.boundingBoxOfPath
        let padding = fontSize * 0.1
        let shift = CGAffineTransform(translationX: padding - bounds.minX, y: padding - bounds.minY)

        let cacheKey = "\(fontName)-\(text)-\(Int(fontSize))-v3"
        let skeleton = SkeletonCache.load(cacheKey) ?? {
            var strokes: [[CGPoint]] = []
            var widths: [Double] = []
            // ~72 px por glifo en altura de mayúscula: suficiente detalle y rápido.
            let scale = 72 / max(CTFontGetCapHeight(font), 1)
            for path in glyphPaths {
                let result = GlyphSkeletonizer.strokes(for: path, scale: scale)
                strokes += result.strokes
                if result.brushWidth > 0 { widths.append(result.brushWidth) }
            }
            let brush = widths.isEmpty ? fontSize * 0.12 : widths.reduce(0, +) / Double(widths.count)
            let computed = SkeletonCache.Entry(strokes: strokes, brushWidth: brush)
            SkeletonCache.save(computed, key: cacheKey)
            return computed
        }()

        return HandwritingLayout(
            textPath: Path(combined).applying(shift),
            strokes: skeleton.strokes.map { $0.map { $0.applying(shift) } },
            brushWidth: skeleton.brushWidth,
            size: CGSize(width: bounds.width + padding * 2, height: bounds.height + padding * 2)
        )
    }
}
