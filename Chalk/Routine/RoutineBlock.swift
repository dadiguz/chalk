import Foundation

/// Un día de rutina ("Día 1 · Upper body") o un extra ("Trabajo abdominal", N veces por semana).
struct RoutineBlock: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let name: String
    let focus: String?
    let timesPerWeek: Int?
    let exercises: [RoutineExercise]

    var isExtra: Bool { timesPerWeek != nil }

    var title: String {
        if let focus, !focus.isEmpty { "\(name) · \(focus)" } else { name }
    }
}
