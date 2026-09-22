import Foundation
import SwiftData

/// Peso por defecto elegido por el usuario. Sobrescribe el `defaultWeightKg` de la rutina.
@Model
final class ExerciseSetting {
    var exerciseId: String
    var defaultWeightKg: Double?
    var updatedAt: Date

    init(exerciseId: String, defaultWeightKg: Double?) {
        self.exerciseId = exerciseId
        self.defaultWeightKg = defaultWeightKg
        self.updatedAt = .now
    }
}
