import Foundation

/// Índice en memoria de los registros para consultar rápido por día y ejercicio.
struct EntryIndex {
    private var statuses: [Date: [String: EntryStatus]] = [:]
    private var weights: [Date: [String: Double]] = [:]
    private(set) var earliestDay: Date?

    init(entries: [WorkoutEntry]) {
        for entry in entries {
            statuses[entry.day, default: [:]][entry.exerciseId] = entry.status
            if let weight = entry.weightKg { weights[entry.day, default: [:]][entry.exerciseId] = weight }
            if earliestDay.map({ entry.day < $0 }) ?? true { earliestDay = entry.day }
        }
    }

    func status(of exerciseId: String, on day: Date) -> EntryStatus? { statuses[day]?[exerciseId] }

    func weight(of exerciseId: String, on day: Date) -> Double? { weights[day]?[exerciseId] }

    func hasAnyDone(on day: Date) -> Bool { statuses[day]?.values.contains(.done) ?? false }

    func doneCount(of block: RoutineBlock, on day: Date) -> Int {
        block.exercises.count(where: { status(of: $0.id, on: day) == .done })
    }

    func isComplete(_ block: RoutineBlock, on day: Date) -> Bool {
        !block.exercises.isEmpty && doneCount(of: block, on: day) == block.exercises.count
    }

    /// Ejercicios hechos ese día (id), para calorías y gráficas.
    func doneExerciseIds(on day: Date) -> [String] {
        statuses[day]?.filter { $0.value == .done }.map(\.key) ?? []
    }
}
