#if DEBUG
import Foundation
import SwiftData

/// Solo Debug: con el argumento `-seedDemoData` llena la base con historial de ejemplo
/// para revisar pantallas y gráficas en el simulador.
enum DebugSeeder {
    static func seedIfRequested(context: ModelContext, store: RoutineStore) {
        guard CommandLine.arguments.contains("-seedDemoData"),
              (try? context.fetchCount(FetchDescriptor<UserProfile>())) == 0 else { return }

        let calendar = Calendar.chalk
        let today = calendar.startOfDay(for: .now)
        let profile = UserProfile(name: "Demo")
        profile.lastCheckInAt = calendar.addingDays(-2, to: today)
        context.insert(profile)

        for week in 0..<6 {
            context.insert(BodyWeightEntry(date: calendar.addingDays(-7 * week, to: today), kg: 80 + Double(week) * 0.6))
        }

        let planner = DayPlanner(store: store, entries: [], makeups: [])
        for offset in (1...42).reversed() {
            let day = calendar.addingDays(-offset, to: today)
            guard offset % 11 != 3 else { continue }
            for planned in planner.plan(for: day) {
                for (position, exercise) in planned.block.exercises.enumerated() {
                    let status: EntryStatus = (offset + position) % 9 == 0 ? .skipped : .done
                    let base = 10 + Double(exercise.sets * 5 + position * 4)
                    let weight = planned.kind == .extra ? nil : base + Double(42 - offset) * 0.25
                    context.insert(WorkoutEntry(day: day, exerciseId: exercise.id, blockId: planned.block.id, status: status, weightKg: weight))
                }
            }
        }

        if let first = planner.plan(for: today).first {
            for exercise in first.block.exercises.prefix(2) {
                context.insert(WorkoutEntry(day: today, exerciseId: exercise.id, blockId: first.block.id, status: .done, weightKg: 22.5))
            }
            if let exercise = first.block.exercises.first {
                context.insert(Note(day: today, exerciseId: exercise.id, text: "Subir a 25 kg la próxima semana."))
            }
        }
        context.insert(Note(day: calendar.addingDays(-1, to: today), exerciseId: nil, text: "Dormí poco, bajé un poco la intensidad."))
    }
}
#endif
