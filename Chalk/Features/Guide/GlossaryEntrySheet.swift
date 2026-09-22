import SwiftUI

/// Definición de un término del glosario, abierta desde un enlace.
struct GlossaryEntrySheet: View {
    let entry: GuideTopic
    @Environment(RoutineStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label(entry.title, systemImage: entry.systemImage)
                        .font(.title2.bold())
                    Text(entry.body)
                        .font(.body)

                    if entry.key == "rpe", let scale = store.routine.meta.effortScale {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(scale.name)
                                .font(.headline)
                            ForEach(scale.levels) { level in
                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                    Text(level.value)
                                        .font(.subheadline.bold().monospacedDigit())
                                        .frame(minWidth: 40)
                                        .padding(.vertical, 3)
                                        .background(Color(.lime).opacity(0.35), in: .capsule)
                                    Text(level.description)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar", systemImage: "xmark", role: .close) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
