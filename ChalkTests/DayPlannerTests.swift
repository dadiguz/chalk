import Foundation
import SwiftData
import Testing
@testable import Chalk

@MainActor
struct DayPlannerTests {
    let calendar = Calendar.chalk
    /// Lunes 21 sep 2026.
    let monday = Calendar.chalk.date(from: DateComponents(year: 2026, month: 9, day: 21))!

    func day(_ offset: Int) -> Date { calendar.addingDays(offset, to: monday) }

    func makeStore() -> RoutineStore {
        func exercise(_ id: String) -> RoutineExercise {
            RoutineExercise(id: id, name: id, sets: 3, reps: "10", rir: nil, rest: "90 seg", notes: nil, defaultWeightKg: nil, gifId: nil)
        }
        let dayA = RoutineBlock(id: "day-a", name: "Día A", focus: nil, timesPerWeek: nil, exercises: [exercise("a1"), exercise("a2")])
        let dayB = RoutineBlock(id: "day-b", name: "Día B", focus: nil, timesPerWeek: nil, exercises: [exercise("b1")])
        let abs = RoutineBlock(id: "abs", name: "Abs", focus: nil, timesPerWeek: 2, exercises: [exercise("crunch")])
        let routine = Routine(
            version: 1,
            meta: RoutineMeta(athlete: "Test", startDate: nil, goal: nil, generalNotes: []),
            days: [dayA, dayB],
            extras: [abs],
            schedule: [
                "monday": ["day-a", "abs"], "tuesday": [], "wednesday": ["day-b", "abs"],
                "thursday": [], "friday": ["day-a"], "saturday": [], "sunday": [],
            ]
        )
        return RoutineStore(routine: routine)
    }

    func entry(_ id: String, _ block: String, _ date: Date, _ status: EntryStatus = .done) -> WorkoutEntry {
        WorkoutEntry(day: date, exerciseId: id, blockId: block, status: status, weightKg: nil)
    }

    func planner(_ entries: [WorkoutEntry], makeups: [MakeupSession] = []) throws -> (DayPlanner, ModelContainer) {
        let container = try ModelContainer(for: WorkoutEntry.self, MakeupSession.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        entries.forEach(container.mainContext.insert)
        makeups.forEach(container.mainContext.insert)
        return (DayPlanner(store: makeStore(), entries: entries, makeups: makeups), container)
    }

    @Test func extraSkippedCarriesOverToNextDay() throws {
        let (planner, _) = try planner([entry("crunch", "abs", day(0), .skipped)])
        let tuesday = planner.extras(on: day(1))
        #expect(tuesday.map(\.id) == ["abs"])
        #expect(tuesday.first?.isCarriedOver == true)
    }

    @Test func extraDisappearsWhenQuotaMet() throws {
        let (planner, _) = try planner([entry("crunch", "abs", day(0)), entry("crunch", "abs", day(1))])
        #expect(planner.extras(on: day(2)).isEmpty)
        #expect(planner.weekExtrasProgress(for: day(2)) == (2, 2))
    }

    @Test func extraNotShownOnUnscheduledDayWhenNothingOwed() throws {
        let (planner, _) = try planner([entry("crunch", "abs", day(0))])
        #expect(planner.extras(on: day(1)).isEmpty)
    }

    @Test func extraQuotaResetsOnMonday() throws {
        let (planner, _) = try planner([entry("crunch", "abs", day(-7)), entry("crunch", "abs", day(-5))])
        #expect(planner.extras(on: day(0)).first?.extraDone == 0)
    }

    @Test func streakSkipsFreeDaysButBreaksOnMissedTrainingDay() throws {
        // Lun hecho, Mar libre, Mié hecho, Jue libre, Vie consultado sin hacer todavía.
        let (planner, _) = try planner([entry("a1", "day-a", day(0)), entry("b1", "day-b", day(2))])
        #expect(planner.streak(today: day(4)) == 2)

        // El viernes anterior (día de rutina) sin actividad rompe la racha.
        let (broken, _) = try self.planner([entry("a1", "day-a", day(0))])
        #expect(broken.streak(today: day(7)) == 0)
    }

    @Test func makeupAppearsOnFreeDay() throws {
        let (planner, _) = try planner([], makeups: [MakeupSession(day: day(5), blockId: "day-b")])
        #expect(planner.isFreeDay(day(5)))
        #expect(planner.mainBlocks(on: day(5)).map(\.kind) == [.makeup])
    }

    @Test func missedYesterdayIgnoresMadeUpDays() throws {
        let (planner, _) = try planner([])
        #expect(planner.missedYesterday(today: day(1)).map(\.id) == ["day-a"])

        let (madeUp, _) = try self.planner([], makeups: [MakeupSession(day: day(5), blockId: "day-a")])
        #expect(madeUp.missedYesterday(today: day(1)).isEmpty)
    }

    @Test func restParsing() {
        let base = RoutineExercise(id: "x", name: "x", sets: 1, reps: "1", rir: nil, rest: "2 min", notes: nil, defaultWeightKg: nil, gifId: nil)
        #expect(base.restSeconds == 120)
    }
}
