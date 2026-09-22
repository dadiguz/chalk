import SwiftUI

struct PlanExerciseCard: View {
    let exercise: RoutineExercise
    let isExtra: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ExerciseThumbnail(gifId: exercise.gifId, size: 116)
                .overlay(alignment: .topTrailing) {
                    if isExtra {
                        Text("Extra")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .foregroundStyle(Color(.onLavender))
                            .background(Color(.lavender), in: .capsule)
                            .padding(6)
                    }
                }
            Text(exercise.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
            Text(exercise.setsAndReps)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 116)
        .contentShape(.rect)
    }
}
