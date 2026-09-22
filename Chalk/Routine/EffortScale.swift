import Foundation

/// Escala de esfuerzo del coach, por ejemplo "RPE · Escala de esfuerzo percibido".
struct EffortScale: Codable, Sendable, Hashable {
    struct Level: Codable, Sendable, Hashable, Identifiable {
        let value: String
        let description: String

        var id: String { value }
    }

    let name: String
    let description: String?
    let levels: [Level]
}
