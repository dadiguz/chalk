import Foundation
import SwiftData

/// Escrituras de "Mi día": marcar ejercicios, pesos, notas y reposiciones.
struct WorkoutLogger {
    let context: ModelContext

    func entry(for exerciseId: String, on day: Date) -> WorkoutEntry? {
        let descriptor = FetchDescriptor<WorkoutEntry>(predicate: #Predicate { $0.day == day && $0.exerciseId == exerciseId })
        return try? context.fetch(descriptor).first
    }

    func setting(for exerciseId: String) -> ExerciseSetting? {
        let descriptor = FetchDescriptor<ExerciseSetting>(predicate: #Predicate { $0.exerciseId == exerciseId })
        return try? context.fetch(descriptor).first
    }

    /// Peso por defecto: el que elegiste en la app, o el de la rutina.
    func defaultWeight(for exercise: RoutineExercise) -> Double? {
        if let setting = setting(for: exercise.id) { return setting.defaultWeightKg }
        return exercise.defaultWeightKg
    }

    /// `nil` regresa el ejercicio a pendiente.
    func setStatus(_ status: EntryStatus?, for exercise: RoutineExercise, in block: RoutineBlock, on day: Date) {
        let existing = entry(for: exercise.id, on: day)
        guard let status else {
            if let existing { context.delete(existing) }
            return
        }
        if let existing {
            existing.status = status
            existing.updatedAt = .now
            if existing.weightKg == nil { existing.weightKg = defaultWeight(for: exercise) }
        } else {
            context.insert(WorkoutEntry(day: day, exerciseId: exercise.id, blockId: block.id, status: status, weightKg: defaultWeight(for: exercise)))
        }
    }

    func setStatus(_ status: EntryStatus?, forAllIn block: RoutineBlock, on day: Date) {
        for exercise in block.exercises {
            setStatus(status, for: exercise, in: block, on: day)
        }
    }

    /// Guarda el peso en el registro del día (si existe) y lo vuelve el nuevo default del ejercicio.
    func setWeight(_ kg: Double?, for exercise: RoutineExercise, on day: Date) {
        if let setting = setting(for: exercise.id) {
            setting.defaultWeightKg = kg
            setting.updatedAt = .now
        } else {
            context.insert(ExerciseSetting(exerciseId: exercise.id, defaultWeightKg: kg))
        }
        entry(for: exercise.id, on: day)?.weightKg = kg
    }

    func addMakeup(_ block: RoutineBlock, on day: Date) {
        context.insert(MakeupSession(day: day, blockId: block.id))
    }

    func removeMakeup(_ block: RoutineBlock, on day: Date) {
        let blockId = block.id
        let descriptor = FetchDescriptor<MakeupSession>(predicate: #Predicate { $0.day == day && $0.blockId == blockId })
        for makeup in (try? context.fetch(descriptor)) ?? [] {
            context.delete(makeup)
        }
        setStatus(nil, forAllIn: block, on: day)
    }

    func addNote(_ text: String, exerciseId: String?, on day: Date) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        context.insert(Note(day: day, exerciseId: exerciseId, text: trimmed))
    }
}
