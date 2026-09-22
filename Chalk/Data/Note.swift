import Foundation
import SwiftData

/// Nota del día (sin ejercicio) o de un ejercicio concreto.
@Model
final class Note {
    var day: Date
    var exerciseId: String?
    var text: String
    var createdAt: Date

    init(day: Date, exerciseId: String?, text: String) {
        self.day = day
        self.exerciseId = exerciseId
        self.text = text
        self.createdAt = .now
    }
}
