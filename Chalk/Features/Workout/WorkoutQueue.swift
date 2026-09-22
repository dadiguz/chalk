import Foundation

/// Ejercicios de un día en el orden en que se hacen: días de rutina, reposiciones y luego extras.
struct WorkoutQueue {
    struct Item: Equatable {
        let exercise: RoutineExercise
        let block: RoutineBlock
    }

    let items: [Item]

    init(plan: [PlannedBlock]) {
        items = plan.flatMap { planned in planned.block.exercises.map { Item(exercise: $0, block: planned.block) } }
    }

    /// Primer ejercicio sin marcar (ni hecho ni saltado).
    func current(index: EntryIndex, day: Date) -> Item? {
        items.first { index.status(of: $0.exercise.id, on: day) == nil }
    }

    /// Siguiente ejercicio sin marcar después del actual.
    func next(after item: Item, index: EntryIndex, day: Date) -> Item? {
        guard let position = items.firstIndex(of: item) else { return nil }
        return items[(position + 1)...].first { index.status(of: $0.exercise.id, on: day) == nil }
    }

    func resolvedCount(index: EntryIndex, day: Date) -> Int {
        items.count(where: { index.status(of: $0.exercise.id, on: day) != nil })
    }
}
