import Foundation

/// Rutina completa leída de `Routine/routine.json`. Es de solo lectura: la app nunca la modifica.
struct Routine: Codable, Sendable {
    let version: Int
    let meta: RoutineMeta
    let days: [RoutineBlock]
    let extras: [RoutineBlock]
    let schedule: [String: [String]]

    init(version: Int, meta: RoutineMeta, days: [RoutineBlock], extras: [RoutineBlock], schedule: [String: [String]]) {
        self.version = version
        self.meta = meta
        self.days = days
        self.extras = extras
        self.schedule = schedule
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        meta = try container.decode(RoutineMeta.self, forKey: .meta)
        days = try container.decode([RoutineBlock].self, forKey: .days)
        extras = try container.decodeIfPresent([RoutineBlock].self, forKey: .extras) ?? []
        schedule = try container.decode([String: [String]].self, forKey: .schedule)
    }

    static let empty = Routine(
        version: 1,
        meta: RoutineMeta(athlete: "", startDate: nil, goal: nil, generalNotes: []),
        days: [],
        extras: [],
        schedule: [:]
    )
}
