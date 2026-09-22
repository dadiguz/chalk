import CoreGraphics

/// Convierte el contorno de un glifo en trazos centrales ordenados como se escribirían.
nonisolated enum GlyphSkeletonizer {
    struct Result {
        let strokes: [[CGPoint]]
        /// Grosor del pincel necesario para cubrir el glifo, en puntos.
        let brushWidth: Double
    }

    static func strokes(for path: CGPath, scale: Double) -> Result {
        let pad = 6.0
        let box = path.boundingBoxOfPath
        let width = Int((box.width * scale + pad * 2).rounded(.up))
        let height = Int((box.height * scale + pad * 2).rounded(.up))
        guard width > 2, height > 2,
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                                      space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        else { return Result(strokes: [], brushWidth: 0) }

        context.translateBy(x: pad, y: pad)
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -box.minX, y: -box.minY)
        context.addPath(path)
        context.setFillColor(gray: 1, alpha: 1)
        context.fillPath()

        guard let data = context.data else { return Result(strokes: [], brushWidth: 0) }
        let bytes = data.bindMemory(to: UInt8.self, capacity: width * height)
        let raw = (0..<(width * height)).map { bytes[$0] > 96 ? UInt8(1) : 0 }

        // La memoria del bitmap tiene la fila 0 en el y máximo del contexto.
        func point(_ x: Int, _ row: Int) -> CGPoint {
            CGPoint(x: box.minX + (Double(x) + 0.5 - pad) / scale,
                    y: box.minY + (Double(height - row) - 0.5 - pad) / scale)
        }

        let filled = BinaryImage(width: width, height: height, pixels: raw).closed(radius: 2).removingSpecks(fraction: 0.06)
        var skeleton = filled.thinned()
        prune(&skeleton, minLength: max(8, height / 6))

        let skeletonCount = skeleton.onCount
        guard skeletonCount > 0 else { return Result(strokes: [], brushWidth: 0) }
        // Grosor medio ≈ área / longitud del esqueleto; se amplía para cubrir bordes irregulares.
        let brush = Double(filled.onCount) / Double(skeletonCount) / scale * 1.9

        let traced = trace(skeleton, displayPoint: point)
        return Result(strokes: traced, brushWidth: brush)
    }

    /// Quita ramas cortas que nacen de la textura irregular del gis.
    private static func prune(_ image: inout BinaryImage, minLength: Int) {
        for _ in 0..<2 {
            for y in 0..<image.height {
                for x in 0..<image.width where image[x, y] == 1 && image.neighborCount(x: x, y: y) == 1 {
                    var branch = [(x, y)]
                    var visited: Set<Int> = [y * image.width + x]
                    var current = (x, y)
                    var reachedJunction = false
                    while branch.count <= minLength {
                        let next = BinaryImage.neighborOffsets
                            .map { (current.0 + $0.0, current.1 + $0.1) }
                            .filter { image[$0.0, $0.1] == 1 && !visited.contains($0.1 * image.width + $0.0) }
                        if next.count != 1 || image.neighborCount(x: next[0].0, y: next[0].1) > 2 {
                            reachedJunction = next.count >= 1
                            break
                        }
                        current = next[0]
                        visited.insert(current.1 * image.width + current.0)
                        branch.append(current)
                    }
                    if reachedJunction && branch.count < minLength {
                        branch.forEach { image[$0.0, $0.1] = 0 }
                    }
                }
            }
        }
    }

    /// Recorre el esqueleto: empieza en el extremo más alto y sigue la dirección de avance en cruces.
    private static func trace(_ image: BinaryImage, displayPoint: (Int, Int) -> CGPoint) -> [[CGPoint]] {
        var visited = Set<Int>()
        var strokes: [[CGPoint]] = []
        let all = (0..<image.height).flatMap { y in (0..<image.width).compactMap { x in image[x, y] == 1 ? (x, y) : nil } }

        func key(_ p: (Int, Int)) -> Int { p.1 * image.width + p.0 }
        func unvisitedNeighbors(_ p: (Int, Int)) -> [(Int, Int)] {
            BinaryImage.neighborOffsets.map { (p.0 + $0.0, p.1 + $0.1) }
                .filter { image[$0.0, $0.1] == 1 && !visited.contains(key($0)) }
        }

        while true {
            let remaining = all.filter { !visited.contains(key($0)) }
            guard !remaining.isEmpty else { break }
            let endpoints = remaining.filter { unvisitedNeighbors($0).count <= 1 }
            let candidates = endpoints.isEmpty ? remaining : endpoints
            // "Más alto" en pantalla = y de pantalla menor; desempata a la izquierda.
            guard let start = candidates.min(by: {
                let a = displayPoint($0.0, $0.1), b = displayPoint($1.0, $1.1)
                return a.y + a.x * 0.35 < b.y + b.x * 0.35
            }) else { break }

            var pixels: [(Int, Int)] = []
            // Si toca un trazo ya dibujado, empieza desde ahí para no dejar huecos.
            if let anchor = BinaryImage.neighborOffsets.map({ (start.0 + $0.0, start.1 + $0.1) })
                .first(where: { image[$0.0, $0.1] == 1 && visited.contains(key($0)) }) {
                pixels.append(anchor)
            }
            var current = start
            var direction = (0.0, 0.0)
            while true {
                visited.insert(key(current))
                pixels.append(current)
                let next = unvisitedNeighbors(current)
                guard !next.isEmpty else { break }
                let chosen = next.max { a, b in
                    let da = (Double(a.0 - current.0), Double(a.1 - current.1))
                    let db = (Double(b.0 - current.0), Double(b.1 - current.1))
                    return da.0 * direction.0 + da.1 * direction.1 < db.0 * direction.0 + db.1 * direction.1
                } ?? next[0]
                let step = (Double(chosen.0 - current.0), Double(chosen.1 - current.1))
                direction = (direction.0 * 0.6 + step.0 * 0.4, direction.1 * 0.6 + step.1 * 0.4)
                current = chosen
            }
            if pixels.count >= 3 {
                strokes.append(smooth(pixels.map { displayPoint($0.0, $0.1) }))
            }
        }
        return strokes
    }

    private static func smooth(_ points: [CGPoint]) -> [CGPoint] {
        guard points.count > 4 else { return points }
        var result: [CGPoint] = [points[0]]
        for i in stride(from: 2, to: points.count - 2, by: 2) {
            let window = points[(i - 2)...(i + 2)]
            let x = window.reduce(0) { $0 + $1.x } / Double(window.count)
            let y = window.reduce(0) { $0 + $1.y } / Double(window.count)
            result.append(CGPoint(x: x, y: y))
        }
        result.append(points[points.count - 1])
        return result
    }
}
