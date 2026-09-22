import SwiftUI

struct DayRingsCard: View {
    let exercisesDone: Int
    let exercisesTotal: Int
    let week: (done: Int, total: Int)
    let extras: (done: Int, total: Int)
    let kcalDone: Double
    let kcalPlanned: Double

    var body: some View {
        HStack(alignment: .top) {
            ProgressRing(progress: ratio(exercisesDone, exercisesTotal), label: "Ejercicios",
                         valueText: exercisesTotal == 0 ? "—" : "\(exercisesDone)/\(exercisesTotal)")
            ProgressRing(progress: ratio(week.done, week.total), label: "Semana")
            ProgressRing(progress: ratio(extras.done, extras.total), label: "Extras",
                         valueText: "\(extras.done)/\(extras.total)", tint: Color(.lavender))
            ProgressRing(progress: kcalPlanned > 0 ? kcalDone / kcalPlanned : 0, label: "≈ kcal",
                         valueText: kcalDone.formatted(.number.precision(.fractionLength(0))), tint: .orange)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color(.surface), in: .rect(cornerRadius: 26))
    }

    private func ratio(_ done: Int, _ total: Int) -> Double {
        total == 0 ? 0 : Double(done) / Double(total)
    }
}
