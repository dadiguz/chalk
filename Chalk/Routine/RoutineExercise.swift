import Foundation

struct RoutineExercise: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let name: String
    let sets: Int
    let reps: String
    let rir: String?
    let rest: String?
    let notes: String?
    let defaultWeightKg: Double?
    let gifId: String?

    /// "3 × 8 a 10"
    var setsAndReps: String { "\(sets) × \(reps)" }

    /// "3 × 8 a 10 · RIR 1 a 2 · 90 seg"
    var prescription: String {
        var parts = [setsAndReps]
        if let rir, !rir.isEmpty { parts.append("RIR \(rir)") }
        if let rest, !rest.isEmpty { parts.append(rest) }
        return parts.joined(separator: " · ")
    }

    /// Descanso en segundos a partir de textos como "90 seg" o "2 min".
    var restSeconds: Double {
        guard let rest else { return 45 }
        let number = rest.split(whereSeparator: { !$0.isNumber && $0 != "." && $0 != "," })
            .first
            .flatMap { Double($0.replacing(",", with: ".")) } ?? 45
        return rest.localizedStandardContains("min") ? number * 60 : number
    }
}
