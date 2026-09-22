import Foundation

/// Series de datos para las gráficas, calculadas a partir de la rutina y los registros.
struct ProgressStats {
    struct DailyKcal: Identifiable {
        let day: Date
        let kcal: Double
        var id: Date { day }
    }

    struct WeeklyAdherence: Identifiable {
        let weekStart: Date
        let series: String
        let percent: Double
        var id: String { "\(weekStart.timeIntervalSince1970)-\(series)" }
    }

    struct LoadPoint: Identifiable {
        let day: Date
        let kg: Double
        var id: Date { day }
    }

    let planner: DayPlanner
    let store: RoutineStore
    let entries: [WorkoutEntry]
    let bodyWeights: [BodyWeightEntry]
    private let calendar = Calendar.chalk

    func dailyKcal(days: Int, endingOn today: Date) -> [DailyKcal] {
        (0..<days).reversed().map { offset in
            let day = calendar.addingDays(-offset, to: today)
            let exercises = planner.index.doneExerciseIds(on: day).compactMap { store.location(ofExercise: $0)?.exercise }
            let kcal = CalorieEstimator.kcal(for: exercises, bodyWeightKg: CalorieEstimator.bodyWeight(on: day, from: bodyWeights))
            return DailyKcal(day: day, kcal: kcal)
        }
    }

    func weekKcal(containing day: Date) -> Double {
        let start = calendar.startOfWeek(for: day)
        return dailyKcal(days: 7, endingOn: calendar.addingDays(6, to: start)).reduce(0) { $0 + $1.kcal }
    }

    func adherence(weeks: Int, endingOn today: Date) -> [WeeklyAdherence] {
        let currentWeek = calendar.startOfWeek(for: today)
        return (0..<weeks).reversed().flatMap { offset -> [WeeklyAdherence] in
            let weekStart = calendar.addingDays(-7 * offset, to: currentWeek)
            let main = planner.weekProgress(for: weekStart)
            let extras = planner.weekExtrasProgress(for: weekStart)
            var result = [WeeklyAdherence(weekStart: weekStart, series: "Rutina",
                                          percent: main.total == 0 ? 0 : Double(main.done) / Double(main.total))]
            if extras.total > 0 {
                result.append(WeeklyAdherence(weekStart: weekStart, series: "Extras",
                                              percent: Double(extras.done) / Double(extras.total)))
            }
            return result
        }
    }

    /// Ejercicios con al menos un registro con peso, ordenados como en la rutina.
    var weightedExercises: [RoutineExercise] {
        let ids = Set(entries.filter { $0.status == .done && $0.weightKg != nil }.map(\.exerciseId))
        return store.allExercises.map(\.exercise).filter { ids.contains($0.id) }
    }

    func load(for exerciseId: String) -> [LoadPoint] {
        entries
            .filter { $0.exerciseId == exerciseId && $0.status == .done }
            .compactMap { entry in entry.weightKg.map { LoadPoint(day: entry.day, kg: $0) } }
            .sorted { $0.day < $1.day }
    }
}
