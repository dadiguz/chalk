import Foundation

/// Detalle descargado de ExerciseGymGifsDB (`Routine/media/<muscle>/<slug>.json`).
struct ExerciseMediaDetails: Codable, Sendable {
    let id: String
    let name: String
    let muscle: String
    let bodyPart: String?
    let equipment: String?
    let category: String?
    let secondaryMuscles: [String]?
    let instructions: [String]?
}
