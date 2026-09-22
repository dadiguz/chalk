import Foundation
import SwiftData
import Testing
@testable import Chalk

@MainActor
struct WorkoutQueueTests {
    let day = Calendar.chalk.date(from: DateComponents(year: 2026, month: 9, day: 21))!

    func exercise(_ id: String) -> RoutineExercise {
        RoutineExercise(id: id, name: id, sets: 3, reps: "10", rir: nil, rest: nil, notes: nil, defaultWeightKg: nil, gifId: nil)
    }

    var plan: [PlannedBlock] {
        let main = RoutineBlock(id: "d1", name: "Día 1", focus: nil, timesPerWeek: nil, exercises: [exercise("a"), exercise("b"), exercise("c")])
        let extra = RoutineBlock(id: "abs", name: "Abs", focus: nil, timesPerWeek: 2, exercises: [exercise("x")])
        return [PlannedBlock(block: main, kind: .scheduled), PlannedBlock(block: extra, kind: .extra)]
    }

    func index(_ statuses: [String: EntryStatus]) -> EntryIndex {
        EntryIndex(entries: statuses.map { WorkoutEntry(day: day, exerciseId: $0.key, blockId: "d1", status: $0.value, weightKg: nil) })
    }

    @Test func startsWithFirstPendingAndIncludesExtrasLast() {
        let queue = WorkoutQueue(plan: plan)
        #expect(queue.items.map(\.exercise.id) == ["a", "b", "c", "x"])
        #expect(queue.current(index: index([:]), day: day)?.exercise.id == "a")
    }

    @Test func advancesPastDoneAndSkipped() {
        let queue = WorkoutQueue(plan: plan)
        let idx = index(["a": .done, "b": .skipped])
        let current = queue.current(index: idx, day: day)
        #expect(current?.exercise.id == "c")
        #expect(current.flatMap { queue.next(after: $0, index: idx, day: day) }?.exercise.id == "x")
        #expect(queue.resolvedCount(index: idx, day: day) == 2)
    }

    @Test func finishesWhenEverythingResolved() {
        let queue = WorkoutQueue(plan: plan)
        #expect(queue.current(index: index(["a": .done, "b": .done, "c": .done, "x": .skipped]), day: day) == nil)
    }
}
