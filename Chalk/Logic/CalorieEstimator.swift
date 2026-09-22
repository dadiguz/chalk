import Foundation

/// Estimación aproximada de calorías con MET de entrenamiento de fuerza.
/// kcal = MET × peso corporal (kg) × horas. Duración = series × (45 s de trabajo + descanso).
enum CalorieEstimator {
    static let strengthMET = 5.0
    static let secondsPerSet = 45.0
    static let fallbackBodyWeightKg = 75.0

    static func kcal(for exercise: RoutineExercise, bodyWeightKg: Double) -> Double {
        let seconds = Double(exercise.sets) * (secondsPerSet + exercise.restSeconds)
        return strengthMET * bodyWeightKg * seconds / 3600
    }

    static func kcal(for exercises: [RoutineExercise], bodyWeightKg: Double) -> Double {
        exercises.reduce(0) { $0 + kcal(for: $1, bodyWeightKg: bodyWeightKg) }
    }

    /// Peso corporal vigente en una fecha: el último registro anterior, o el primero que exista.
    static func bodyWeight(on date: Date, from entries: [BodyWeightEntry]) -> Double {
        let sorted = entries.sorted { $0.date < $1.date }
        return sorted.last(where: { $0.date <= date })?.kg ?? sorted.first?.kg ?? fallbackBodyWeightKg
    }
}
