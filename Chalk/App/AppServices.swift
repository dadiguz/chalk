import SwiftData

/// Instancias compartidas entre la interfaz y los App Intents (por ejemplo, el ✓ de la Live Activity),
/// para que ambos escriban en el mismo contenedor de SwiftData.
enum AppServices {
    static let routineStore = RoutineStore()

    static let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for:
                WorkoutEntry.self,
                ExerciseSetting.self,
                Note.self,
                MakeupSession.self,
                UserProfile.self,
                BodyWeightEntry.self,
                ProgressPhoto.self
            )
        } catch {
            fatalError("No se pudo abrir la base de datos local: \(error)")
        }
    }()
}
