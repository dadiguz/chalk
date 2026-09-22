import SwiftUI

/// Iniciar / seguir un entrenamiento con Live Activity.
struct WorkoutSessionCard: View {
    let session: WorkoutSession
    let currentName: String?
    let resolved: Int
    let total: Int
    let onStart: () -> Void
    let onStop: () -> Void

    var body: some View {
        if session.isRunning {
            HStack(spacing: 14) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundStyle(Color(.onLime))
                    .frame(width: 48, height: 48)
                    .background(Color(.lime), in: .circle)
                    .symbolEffect(.pulse, options: .repeating)

                VStack(alignment: .leading, spacing: 2) {
                    Text("En curso · \(min(resolved + 1, total)) de \(total)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(currentName ?? "Terminando…")
                        .font(.headline)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Button("Terminar", action: onStop)
                    .buttonStyle(.glass)
            }
            .card(tint: Color(.lime))
        } else {
            Button(action: onStart) {
                Label("Iniciar entrenamiento", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .accessibilityHint("Muestra el ejercicio actual en la pantalla de bloqueo y la Dynamic Island")
        }
    }
}
