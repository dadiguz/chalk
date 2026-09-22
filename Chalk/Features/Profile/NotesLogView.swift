import SwiftData
import SwiftUI

/// Log completo de notas, agrupado por fecha.
struct NotesLogView: View {
    @Environment(RoutineStore.self) private var store
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    @State private var search = ""

    private var filtered: [Note] {
        guard !search.isEmpty else { return notes }
        return notes.filter { note in
            note.text.localizedStandardContains(search)
                || (exerciseName(note)?.localizedStandardContains(search) ?? false)
        }
    }

    private var groups: [(day: Date, notes: [Note])] {
        Dictionary(grouping: filtered, by: \.day)
            .map { ($0.key, $0.value) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        List {
            ForEach(groups, id: \.day) { group in
                Section {
                    ForEach(group.notes) { note in
                        VStack(alignment: .leading, spacing: 4) {
                            Label(exerciseName(note) ?? "Nota del día",
                                  systemImage: note.exerciseId == nil ? "calendar" : "dumbbell")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(note.text)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete { offsets in
                        offsets.map { group.notes[$0] }.forEach(context.delete)
                    }
                } header: {
                    Text(group.day, format: .dateTime.weekday(.wide).day().month(.wide).year())
                }
            }
        }
        .overlay {
            if notes.isEmpty {
                ContentUnavailableView("Sin notas", systemImage: "note.text",
                                       description: Text("Agrega notas desde Mi día o desde el detalle de un ejercicio."))
            } else if filtered.isEmpty {
                ContentUnavailableView.search(text: search)
            }
        }
        .searchable(text: $search, prompt: "Buscar en notas")
        .navigationTitle("Mis notas")
    }

    private func exerciseName(_ note: Note) -> String? {
        note.exerciseId.flatMap { store.location(ofExercise: $0)?.exercise.name }
    }
}
