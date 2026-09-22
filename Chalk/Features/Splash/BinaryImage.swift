import CoreGraphics

/// Imagen binaria (0/1) para esqueletizar glifos.
nonisolated struct BinaryImage {
    let width: Int
    let height: Int
    var pixels: [UInt8]

    init(width: Int, height: Int, pixels: [UInt8]) {
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    subscript(x: Int, y: Int) -> UInt8 {
        get { x >= 0 && y >= 0 && x < width && y < height ? pixels[y * width + x] : 0 }
        set { if x >= 0 && y >= 0 && x < width && y < height { pixels[y * width + x] = newValue } }
    }

    /// Vecinos en el orden de Zhang-Suen: P2 (arriba) y luego en sentido horario.
    static let neighborOffsets = [(0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1)]

    func neighborCount(x: Int, y: Int) -> Int {
        Self.neighborOffsets.reduce(0) { $0 + Int(self[x + $1.0, y + $1.1]) }
    }

    var onCount: Int { pixels.reduce(0) { $0 + Int($1) } }

    /// Quita islas pequeñas (motas de polvo de gis) con menos de `fraction` del área total.
    func removingSpecks(fraction: Double) -> BinaryImage {
        var result = self
        var label = [Int32](repeating: 0, count: pixels.count)
        var components: [[Int]] = []
        for start in pixels.indices where pixels[start] == 1 && label[start] == 0 {
            var stack = [start]
            var members: [Int] = []
            label[start] = Int32(components.count + 1)
            while let i = stack.popLast() {
                members.append(i)
                let x = i % width, y = i / width
                for (dx, dy) in Self.neighborOffsets {
                    let nx = x + dx, ny = y + dy
                    guard nx >= 0, ny >= 0, nx < width, ny < height else { continue }
                    let n = ny * width + nx
                    if pixels[n] == 1 && label[n] == 0 {
                        label[n] = Int32(components.count + 1)
                        stack.append(n)
                    }
                }
            }
            components.append(members)
        }
        let total = components.reduce(0) { $0 + $1.count }
        let minimum = Int(Double(total) * fraction)
        for component in components where component.count < minimum {
            for i in component { result.pixels[i] = 0 }
        }
        return result
    }

    /// Dilatación seguida de erosión: rellena los huecos de la textura de gis.
    func closed(radius: Int) -> BinaryImage {
        morph(radius: radius, keep: 1).morph(radius: radius, keep: 0)
    }

    /// `keep == 1`: dilatación (max). `keep == 0`: erosión (min). Kernel cuadrado separable.
    private func morph(radius: Int, keep: UInt8) -> BinaryImage {
        var horizontal = self
        for y in 0..<height {
            for x in 0..<width {
                var value = keep == 1 ? UInt8(0) : UInt8(1)
                for dx in -radius...radius {
                    let sample = (x + dx < 0 || x + dx >= width) ? UInt8(0) : pixels[y * width + x + dx]
                    if sample == keep { value = keep; break }
                }
                horizontal.pixels[y * width + x] = value
            }
        }
        var result = horizontal
        for y in 0..<height {
            for x in 0..<width {
                var value = keep == 1 ? UInt8(0) : UInt8(1)
                for dy in -radius...radius {
                    let sample = (y + dy < 0 || y + dy >= height) ? UInt8(0) : horizontal.pixels[(y + dy) * width + x]
                    if sample == keep { value = keep; break }
                }
                result.pixels[y * width + x] = value
            }
        }
        return result
    }

    /// Adelgazamiento de Zhang-Suen hasta un esqueleto de 1 px.
    /// Requiere un borde de al menos 1 px vacío (los glifos se rasterizan con margen).
    func thinned() -> BinaryImage {
        var px = pixels
        let w = width
        var remove: [Int] = []
        remove.reserveCapacity(w * height / 4)
        var changed = true
        while changed {
            changed = false
            for pass in 0..<2 {
                remove.removeAll(keepingCapacity: true)
                for y in 1..<(height - 1) {
                    let row = y * w
                    for x in 1..<(w - 1) where px[row + x] == 1 {
                        let i = row + x
                        let p2 = px[i - w], p3 = px[i - w + 1], p4 = px[i + 1], p5 = px[i + w + 1]
                        let p6 = px[i + w], p7 = px[i + w - 1], p8 = px[i - 1], p9 = px[i - w - 1]
                        let b = Int(p2) + Int(p3) + Int(p4) + Int(p5) + Int(p6) + Int(p7) + Int(p8) + Int(p9)
                        guard b >= 2 && b <= 6 else { continue }
                        var a = 0
                        if p2 == 0 && p3 == 1 { a += 1 }
                        if p3 == 0 && p4 == 1 { a += 1 }
                        if p4 == 0 && p5 == 1 { a += 1 }
                        if p5 == 0 && p6 == 1 { a += 1 }
                        if p6 == 0 && p7 == 1 { a += 1 }
                        if p7 == 0 && p8 == 1 { a += 1 }
                        if p8 == 0 && p9 == 1 { a += 1 }
                        if p9 == 0 && p2 == 1 { a += 1 }
                        guard a == 1 else { continue }
                        let ok = pass == 0
                            ? (p2 & p4 & p6) == 0 && (p4 & p6 & p8) == 0
                            : (p2 & p4 & p8) == 0 && (p2 & p6 & p8) == 0
                        if ok { remove.append(i) }
                    }
                }
                for i in remove { px[i] = 0 }
                changed = changed || !remove.isEmpty
            }
        }
        return BinaryImage(width: width, height: height, pixels: px)
    }
}
