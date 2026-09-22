#if DEBUG
import SwiftUI

/// Solo Debug (`-liveActivityPreview YES`): muestra la vista de pantalla de bloqueo con datos de ejemplo,
/// porque el simulador no permite capturar la pantalla de bloqueo.
struct LiveActivityPreview: View {
    private let states: [WorkoutActivityAttributes.ContentState] = [
        .init(exerciseId: "aductor-maquina", name: "Aductor en máquina", blockName: "Día 2", isExtra: false, sets: 3,
              reps: "12 a 15", rir: "0 a 1", rest: "90 seg", weightKg: 22.5,
              mediaPath: MediaLibrary.bundleRelativeMediaPath(for: "adductors/lever-seated-hip-adduction"),
              completed: 2, total: 9, nextName: "Curl sentado en máquina", isFinished: false),
        .init(exerciseId: "crunch-acostado", name: "Crunch acostado", blockName: "Trabajo abdominal", isExtra: true, sets: 4,
              reps: "30", rir: nil, rest: nil, weightKg: nil,
              mediaPath: MediaLibrary.bundleRelativeMediaPath(for: "abs/crunch-floor"),
              completed: 6, total: 9, nextName: "Plancha abdominal", isFinished: false),
        .init(exerciseId: "x", name: "", blockName: "", isExtra: false, sets: 0, reps: "", rir: nil, rest: nil, weightKg: nil,
              mediaPath: nil, completed: 9, total: 9, nextName: nil, isFinished: true),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(states, id: \.self) { state in
                    WorkoutLockScreenView(title: "Día 2 · Tren inferior", state: state)
                        .background(LiveActivityPalette.background, in: .rect(cornerRadius: 24))
                }
            }
            .padding()
        }
        .background(Color(.systemGray5))
    }
}
#endif
