import AppIntents
import SwiftUI

// Piezas visuales de la Live Activity, compartidas por la pantalla de bloqueo y la Dynamic Island.

struct ExerciseActivityThumbnail: View {
    let mediaPath: String?
    var size = 52.0

    var body: some View {
        Group {
            if let image = ExerciseImageLoader.thumbnail(relativePath: mediaPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .background(.white)
            } else {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(LiveActivityPalette.surface)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: size * 0.24))
    }
}

/// Botón circular ✓ que marca el ejercicio actual.
struct CompleteExerciseButton: View {
    let state: WorkoutActivityAttributes.ContentState
    var size = 50.0

    var body: some View {
        Button(intent: CompleteExerciseIntent(exerciseId: state.exerciseId)) {
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(LiveActivityPalette.onAccent)
                .frame(width: size, height: size)
                .background(state.isExtra ? LiveActivityPalette.lavender : LiveActivityPalette.lime, in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Marcar \(state.name) como hecho")
    }
}

/// Fila de datos: series, repeticiones, descanso y lo que haya (RIR, peso).
struct WorkoutStatsRow: View {
    let state: WorkoutActivityAttributes.ContentState

    private var items: [(String, String)] {
        var result = [("Series", "\(state.sets)"), ("Reps", state.reps)]
        if let rest = state.rest { result.append(("Descanso", rest)) }
        if let weight = state.weightKg {
            result.append(("Peso", "\(weight.formatted(.number.precision(.fractionLength(0...1)))) kg"))
        } else if let rir = state.rir {
            result.append(("RIR", rir))
        }
        return result
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items, id: \.0) { item in
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.0)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                    Text(item.1)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.white.opacity(0.08), in: .rect(cornerRadius: 10))
            }
        }
    }
}

/// Vista de la pantalla de bloqueo / banner.
struct WorkoutLockScreenView: View {
    let title: String
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: "flame.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LiveActivityPalette.lime)
                    .lineLimit(1)
                Spacer()
                Text("\(min(state.completed + 1, state.total))/\(state.total)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.7))
            }

            if state.isFinished {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.largeTitle)
                        .foregroundStyle(LiveActivityPalette.lime)
                    VStack(alignment: .leading) {
                        Text("¡Entrenamiento completo!")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("\(state.completed) ejercicios")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            } else {
                HStack(spacing: 12) {
                    ExerciseActivityThumbnail(mediaPath: state.mediaPath)
                    VStack(alignment: .leading, spacing: 2) {
                        if state.isExtra {
                            Text("Extra · \(state.blockName)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(LiveActivityPalette.lavender)
                        }
                        Text(state.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    Spacer(minLength: 4)
                    CompleteExerciseButton(state: state)
                }

                WorkoutStatsRow(state: state)

                VStack(spacing: 6) {
                    ProgressView(value: state.progress)
                        .tint(LiveActivityPalette.lime)
                    if let next = state.nextName {
                        Text("Sigue: \(next)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .padding(16)
    }
}
