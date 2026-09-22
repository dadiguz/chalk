import Foundation

/// Guarda en Caches los trazos calculados para no esqueletizar en cada arranque.
nonisolated enum SkeletonCache {
    struct Entry: Codable {
        let strokes: [[CGPoint]]
        let brushWidth: Double
    }

    private static func url(_ key: String) -> URL {
        URL.cachesDirectory.appending(path: "handwriting-\(key).json")
    }

    static func load(_ key: String) -> Entry? {
        guard let data = try? Data(contentsOf: url(key)) else { return nil }
        return try? JSONDecoder().decode(Entry.self, from: data)
    }

    static func save(_ entry: Entry, key: String) {
        guard let data = try? JSONEncoder().encode(entry) else { return }
        try? data.write(to: url(key), options: .atomic)
    }
}
