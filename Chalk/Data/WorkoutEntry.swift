import Foundation
import SwiftData

/// Un registro por ejercicio por fecha. Es la base de la racha y las gráficas.
@Model
final class WorkoutEntry {
    var day: Date
    var exerciseId: String
    var blockId: String
    var statusRaw: String
    var weightKg: Double?
    var updatedAt: Date

    init(day: Date, exerciseId: String, blockId: String, status: EntryStatus, weightKg: Double?) {
        self.day = day
        self.exerciseId = exerciseId
        self.blockId = blockId
        self.statusRaw = status.rawValue
        self.weightKg = weightKg
        self.updatedAt = .now
    }

    var status: EntryStatus {
        get { EntryStatus(rawValue: statusRaw) ?? .skipped }
        set { statusRaw = newValue.rawValue }
    }
}
