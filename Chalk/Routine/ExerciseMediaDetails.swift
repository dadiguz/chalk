import Foundation

/// Detalle de un ejercicio: de ExerciseGymGifsDB (`Routine/media/<muscle>/<slug>.json`)
/// o del catálogo propio de Chalk (`Catalog/exercises.json`).
struct ExerciseMediaDetails: Codable, Sendable {
    let id: String
    let name: String
    let muscle: String
    let bodyPart: String?
    let equipment: String?
    let category: String?
    let secondaryMuscles: [String]?
    let instructions: [String]?
    /// Solo catálogo propio: descripción general del ejercicio.
    let description: String?
    /// Solo catálogo propio: imagen fija con su crédito.
    let image: CatalogImage?
}
