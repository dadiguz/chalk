import Foundation

/// Identifica un ejercicio a mostrar en detalle, con la fecha desde la que se abrió.
struct ExerciseRef: Identifiable, Hashable {
    let exerciseId: String
    var day: Date?

    var id: String { exerciseId }
}
