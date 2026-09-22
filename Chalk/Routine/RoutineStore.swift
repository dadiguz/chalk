import Foundation
import Observation

/// Carga la rutina del bundle. Usa `routine.json` si existe y si no, `routine.example.json`.
@Observable
final class RoutineStore {
    let routine: Routine
    let isExample: Bool
    let loadError: String?

    private let blocksById: [String: RoutineBlock]
    private let exercisesById: [String: ExerciseLocation]

    convenience init(bundle: Bundle = .main) {
        let folder = bundle.resourceURL?.appending(path: "Routine")
        var loaded: Routine?
        var example = false
        var failure: String?

        for (file, isExampleFile) in [("routine.json", false), ("routine.example.json", true)] {
            guard let url = folder?.appending(path: file), FileManager.default.fileExists(atPath: url.path) else { continue }
            do {
                loaded = try JSONDecoder().decode(Routine.self, from: Data(contentsOf: url))
                example = isExampleFile
                break
            } catch {
                failure = "No se pudo leer \(file): \(error.localizedDescription)"
            }
        }

        self.init(
            routine: loaded ?? .empty,
            isExample: example,
            loadError: loaded == nil ? (failure ?? "No se encontró ninguna rutina en el bundle.") : nil
        )
    }

    init(routine: Routine, isExample: Bool = false, loadError: String? = nil) {
        self.routine = routine
        self.isExample = isExample
        self.loadError = loadError

        let blocks = routine.days + routine.extras
        blocksById = Dictionary(blocks.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var exercises: [String: ExerciseLocation] = [:]
        for block in blocks {
            for exercise in block.exercises where exercises[exercise.id] == nil {
                exercises[exercise.id] = ExerciseLocation(exercise: exercise, block: block)
            }
        }
        exercisesById = exercises
    }

    func block(id: String) -> RoutineBlock? { blocksById[id] }

    func location(ofExercise id: String) -> ExerciseLocation? { exercisesById[id] }

    /// Días de rutina (no extras) programados para ese día de la semana.
    func scheduledDays(on weekday: Weekday) -> [RoutineBlock] {
        (routine.schedule[weekday.rawValue] ?? []).compactMap { blocksById[$0] }.filter { !$0.isExtra }
    }

    func isExtra(_ extra: RoutineBlock, scheduledOn weekday: Weekday) -> Bool {
        routine.schedule[weekday.rawValue]?.contains(extra.id) ?? false
    }

    /// Todos los bloques de ese día de la semana, días primero y extras después.
    func scheduledBlocks(on weekday: Weekday) -> [RoutineBlock] {
        let ids = routine.schedule[weekday.rawValue] ?? []
        let blocks = ids.compactMap { blocksById[$0] }
        return blocks.filter { !$0.isExtra } + blocks.filter(\.isExtra)
    }

    var allExercises: [ExerciseLocation] {
        (routine.days + routine.extras).flatMap { block in
            block.exercises.map { ExerciseLocation(exercise: $0, block: block) }
        }
    }
}
