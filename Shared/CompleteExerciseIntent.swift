import AppIntents
import Foundation

/// Botón ✓ de la Live Activity. Corre en el proceso de la app: marca el ejercicio como hecho
/// y avanza la actividad al siguiente.
struct CompleteExerciseIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Completar ejercicio"
    static let description = IntentDescription("Marca el ejercicio actual como hecho y muestra el siguiente.")
    static let isDiscoverable = false

    @Parameter(title: "Ejercicio")
    var exerciseId: String

    init() {}

    init(exerciseId: String) {
        self.exerciseId = exerciseId
    }

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        await WorkoutSession.shared.complete(exerciseId: exerciseId)
        #endif
        return .result()
    }
}
