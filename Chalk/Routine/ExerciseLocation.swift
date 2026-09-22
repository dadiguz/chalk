import Foundation

/// Un ejercicio junto con el bloque (día o extra) al que pertenece.
struct ExerciseLocation: Sendable, Hashable {
    let exercise: RoutineExercise
    let block: RoutineBlock
}
