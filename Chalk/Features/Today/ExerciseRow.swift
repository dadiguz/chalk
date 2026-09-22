import SwiftUI

struct ExerciseRow: View {
    let exercise: RoutineExercise
    let status: EntryStatus?
    let weightKg: Double?
    let hasNotes: Bool
    var accent: Color = Color(.lime)
    var onAccent: Color = Color(.onLime)
    let onStatus: (EntryStatus?) -> Void
    let onWeight: (Double?) -> Void
    let onOpen: () -> Void

    @State private var isEditingWeight = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Button(action: onOpen) {
                    HStack(spacing: 12) {
                        ExerciseThumbnail(gifId: exercise.gifId)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(exercise.name)
                                .font(.headline)
                                .strikethrough(status == .skipped)
                                .foregroundStyle(status == .skipped ? .secondary : .primary)
                                .multilineTextAlignment(.leading)
                            Text(exercise.prescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Ver detalles y demostración")

                StatusButtons(status: status, accent: accent, onAccent: onAccent, onChange: onStatus)
            }

            HStack(spacing: 8) {
                Button {
                    isEditingWeight = true
                } label: {
                    Label(weightText, systemImage: "scalemass")
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .popover(isPresented: $isEditingWeight) {
                    WeightEditor(initial: weightKg, onSave: onWeight)
                        .presentationCompactAdaptation(.popover)
                }

                if hasNotes {
                    Image(systemName: "note.text")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Tiene notas")
                }
                if exercise.gifId == nil || MediaLibrary.gifURL(for: exercise.gifId) == nil {
                    Label("Sin GIF", systemImage: "eye.slash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 68)
        }
        .padding(.vertical, 6)
    }

    private var weightText: String {
        guard let weightKg else { return "Añadir peso" }
        return "\(weightKg.formatted(.number.precision(.fractionLength(0...1)))) kg"
    }
}
