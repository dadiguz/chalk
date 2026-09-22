@preconcurrency import ActivityKit
import Foundation
import Observation
import SwiftData

/// Entrenamiento en curso: mantiene la Live Activity con el ejercicio actual y la avanza
/// cuando se marca como hecho (desde la actividad o desde la app).
@Observable
final class WorkoutSession {
    static let shared = WorkoutSession()

    private(set) var activity: Activity<WorkoutActivityAttributes>?
    private(set) var currentExerciseId: String?
    var errorMessage: String?

    var isRunning: Bool { activity != nil }

    private var store: RoutineStore { AppServices.routineStore }
    private var context: ModelContext { AppServices.modelContainer.mainContext }
    private let calendar = Calendar.chalk

    /// Retoma una actividad que siguiera viva al volver a abrir la app.
    func restore() async {
        guard activity == nil, let existing = Activity<WorkoutActivityAttributes>.activities.first else { return }
        activity = existing
        await refresh()
    }

    func start(day: Date) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            errorMessage = "Las Actividades en vivo están desactivadas para Chalk. Actívalas en Ajustes › Chalk."
            return
        }
        await stop()

        let planner = makePlanner()
        let plan = planner.plan(for: day)
        let queue = WorkoutQueue(plan: plan)
        guard let state = contentState(queue: queue, planner: planner, day: day), !state.isFinished else {
            errorMessage = "No hay ejercicios pendientes para hoy."
            return
        }

        let title = plan.first(where: { $0.kind != .extra })?.block.title ?? plan.first?.block.name ?? "Entrenamiento"
        let attributes = WorkoutActivityAttributes(title: title, day: day, startedAt: .now)
        do {
            activity = try Activity.request(attributes: attributes, content: ActivityContent(state: state, staleDate: nil))
            currentExerciseId = state.exerciseId
        } catch {
            errorMessage = "No se pudo iniciar la actividad: \(error.localizedDescription)"
        }
    }

    /// Llamado por el ✓ de la Live Activity.
    func complete(exerciseId: String) async {
        if activity == nil { await restore() }
        guard let activity, let location = store.location(ofExercise: exerciseId) else { return }
        let logger = WorkoutLogger(context: context)
        logger.setStatus(.done, for: location.exercise, in: location.block, on: activity.attributes.day)
        try? context.save()
        await refresh()
    }

    /// Recalcula el ejercicio actual a partir de la base de datos y actualiza la actividad.
    func refresh() async {
        guard let activity else { return }
        let day = activity.attributes.day
        let planner = makePlanner()
        let queue = WorkoutQueue(plan: planner.plan(for: day))
        guard let state = contentState(queue: queue, planner: planner, day: day) else { return }
        guard state != activity.content.state else { return }

        currentExerciseId = state.isFinished ? nil : state.exerciseId
        let content = ActivityContent(state: state, staleDate: nil)
        if state.isFinished {
            await activity.end(content, dismissalPolicy: .after(.now.addingTimeInterval(15 * 60)))
            self.activity = nil
        } else {
            await activity.update(content)
        }
    }

    func stop() async {
        for running in Activity<WorkoutActivityAttributes>.activities {
            await running.end(nil, dismissalPolicy: .immediate)
        }
        activity = nil
        currentExerciseId = nil
    }

    // MARK: - Estado

    private func makePlanner() -> DayPlanner {
        let entries = (try? context.fetch(FetchDescriptor<WorkoutEntry>())) ?? []
        let makeups = (try? context.fetch(FetchDescriptor<MakeupSession>())) ?? []
        return DayPlanner(store: store, entries: entries, makeups: makeups)
    }

    private func contentState(queue: WorkoutQueue, planner: DayPlanner, day: Date) -> WorkoutActivityAttributes.ContentState? {
        guard !queue.items.isEmpty else { return nil }
        let index = planner.index
        let resolved = queue.resolvedCount(index: index, day: day)

        guard let current = queue.current(index: index, day: day) else {
            let last = queue.items[queue.items.count - 1]
            return makeState(last, completed: resolved, total: queue.items.count, next: nil, finished: true, index: index, day: day)
        }
        let next = queue.next(after: current, index: index, day: day)
        return makeState(current, completed: resolved, total: queue.items.count, next: next, finished: false, index: index, day: day)
    }

    private func makeState(_ item: WorkoutQueue.Item, completed: Int, total: Int, next: WorkoutQueue.Item?,
                           finished: Bool, index: EntryIndex, day: Date) -> WorkoutActivityAttributes.ContentState {
        let exercise = item.exercise
        let weight = index.weight(of: exercise.id, on: day) ?? WorkoutLogger(context: context).defaultWeight(for: exercise)
        return WorkoutActivityAttributes.ContentState(
            exerciseId: exercise.id,
            name: exercise.name,
            blockName: item.block.name,
            isExtra: item.block.isExtra,
            sets: exercise.sets,
            reps: exercise.reps,
            rir: exercise.rir,
            rest: exercise.rest,
            weightKg: weight,
            mediaPath: MediaLibrary.bundleRelativeMediaPath(for: exercise.gifId),
            completed: completed,
            total: total,
            nextName: next?.exercise.name,
            isFinished: finished
        )
    }
}
