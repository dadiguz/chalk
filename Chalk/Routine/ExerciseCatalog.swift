import Foundation

/// `Catalog/exercises.json`: ejercicios que no existen en ExerciseGymGifsDB.
struct ExerciseCatalog: Codable, Sendable {
    let version: Int
    let exercises: [ExerciseMediaDetails]

    static let idPrefix = "chalk/"
}
