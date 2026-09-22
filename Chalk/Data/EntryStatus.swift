import Foundation

/// Estado de un ejercicio en una fecha. "Pendiente" es la ausencia de registro.
enum EntryStatus: String, Codable, Sendable {
    case done
    case skipped
}
