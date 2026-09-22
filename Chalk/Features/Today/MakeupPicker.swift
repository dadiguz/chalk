import SwiftUI

/// Elige qué día de rutina reponer. Los no hechos esta semana aparecen primero.
struct MakeupPicker: View {
    let options: [(block: RoutineBlock, done: Bool)]
    let excluded: Set<String>
    let onPick: (RoutineBlock) -> Void
    @Environment(\.dismiss) private var dismiss

    private var pending: [(block: RoutineBlock, done: Bool)] { options.filter { !$0.done && !excluded.contains($0.block.id) } }
    private var done: [(block: RoutineBlock, done: Bool)] { options.filter { $0.done && !excluded.contains($0.block.id) } }

    var body: some View {
        NavigationStack {
            List {
                if !pending.isEmpty {
                    Section("Pendientes esta semana") {
                        ForEach(pending, id: \.block.id) { row($0.block, done: false) }
                    }
                }
                if !done.isEmpty {
                    Section("Ya hechos (repetir)") {
                        ForEach(done, id: \.block.id) { row($0.block, done: true) }
                    }
                }
            }
            .navigationTitle("Reponer un día")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", systemImage: "xmark", role: .cancel) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(_ block: RoutineBlock, done: Bool) -> some View {
        Button {
            onPick(block)
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(block.name).font(.headline)
                    if let focus = block.focus { Text(focus).font(.subheadline).foregroundStyle(.secondary) }
                }
                Spacer()
                Text("^[\(block.exercises.count) ejercicio](inflect: true)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if done {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
