import ActivityKit
import Foundation

/// Live Activity de un entrenamiento: muestra el ejercicio actual y permite marcarlo como hecho.
nonisolated struct WorkoutActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable, Sendable {
        var exerciseId: String
        var name: String
        var blockName: String
        var isExtra: Bool
        var sets: Int
        var reps: String
        var rir: String?
        var rest: String?
        var weightKg: Double?
        /// Ruta del GIF o imagen relativa al bundle de la app (la extensión la lee desde ahí).
        var mediaPath: String?
        /// Ejercicios ya resueltos (hechos o saltados) y total del día.
        var completed: Int
        var total: Int
        var nextName: String?
        var isFinished: Bool

        /// "3 × 8 a 10"
        var setsAndReps: String { "\(sets) × \(reps)" }

        var progress: Double { total == 0 ? 0 : Double(completed) / Double(total) }
    }

    /// "Día 2 · Tren inferior"
    var title: String
    /// Día del entrenamiento (inicio del día), para escribir los registros en la fecha correcta.
    var day: Date
    var startedAt: Date
}
