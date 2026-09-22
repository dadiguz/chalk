import SwiftUI

/// Tarjeta de un día de rutina o de un extra, con sus ejercicios.
struct BlockCard: View {
    let planned: PlannedBlock
    let day: Date
    let index: EntryIndex
    let weightFor: (RoutineExercise) -> Double?
    let exercisesWithNotes: Set<String>
    var currentExerciseId: String?
    let onStatus: (RoutineExercise, EntryStatus?) -> Void
    let onBlockStatus: (EntryStatus?) -> Void
    let onWeight: (RoutineExercise, Double?) -> Void
    let onOpen: (RoutineExercise) -> Void
    var onRemoveMakeup: (() -> Void)?

    private var isExtra: Bool { planned.kind == .extra }
    private var accent: Color { isExtra ? Color(.lavender) : Color(.lime) }
    private var onAccent: Color { isExtra ? Color(.onLavender) : Color(.onLime) }

    private var blockStatus: EntryStatus? {
        let statuses = planned.block.exercises.map { index.status(of: $0.id, on: day) }
        if statuses.allSatisfy({ $0 == .done }) { return .done }
        if statuses.allSatisfy({ $0 == .skipped }) { return .skipped }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            ForEach(planned.block.exercises) { exercise in
                ExerciseRow(
                    exercise: exercise,
                    status: index.status(of: exercise.id, on: day),
                    weightKg: index.weight(of: exercise.id, on: day) ?? weightFor(exercise),
                    hasNotes: exercisesWithNotes.contains(exercise.id),
                    isCurrent: exercise.id == currentExerciseId,
                    accent: accent,
                    onAccent: onAccent,
                    onStatus: { onStatus(exercise, $0) },
                    onWeight: { onWeight(exercise, $0) },
                    onOpen: { onOpen(exercise) }
                )
                if exercise.id != planned.block.exercises.last?.id {
                    Divider().padding(.leading, 68)
                }
            }
        }
        .card(tint: isExtra ? Color(.lavender) : nil)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                badges
                Text(planned.block.name)
                    .font(.title3.bold())
                if let focus = planned.block.focus, !focus.isEmpty {
                    Text(focus)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let onRemoveMakeup {
                Menu("Opciones", systemImage: "ellipsis") {
                    Button("Quitar reposición", systemImage: "arrow.uturn.backward", role: .destructive, action: onRemoveMakeup)
                }
                .labelStyle(.iconOnly)
                .frame(width: 32, height: 42)
            }
            StatusButtons(status: blockStatus, accent: accent, onAccent: onAccent, onChange: onBlockStatus)
                .accessibilityLabel("Marcar todo el bloque")
        }
    }

    @ViewBuilder private var badges: some View {
        let items = badgeItems
        if !items.isEmpty {
            HStack(spacing: 6) {
                ForEach(items, id: \.self) { text in
                    Text(text)
                        .font(.caption2.bold())
                        .textCase(.uppercase)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(onAccent)
                        .background(accent, in: .capsule)
                }
            }
        }
    }

    private var badgeItems: [String] {
        switch planned.kind {
        case .scheduled: []
        case .makeup: ["Repuesto"]
        case .extra:
            ["Extra · \(planned.extraDone)/\(planned.extraQuota) esta semana"] + (planned.isCarriedOver ? ["Pendiente"] : [])
        }
    }
}
