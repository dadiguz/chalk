import Charts
import SwiftData
import SwiftUI

/// Detalle de un ejercicio: GIF, lo que dice el plan, peso por defecto, instrucciones, historial y notas.
struct ExerciseDetailView: View {
    let ref: ExerciseRef

    @Environment(RoutineStore.self) private var store
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var entries: [WorkoutEntry]
    @Query private var notes: [Note]
    @Query private var settings: [ExerciseSetting]

    @State private var isEditingWeight = false
    @State private var isAddingNote = false
    @State private var glossaryEntry: GuideTopic?

    private var glossary: Glossary { Glossary(meta: store.routine.meta) }

    init(ref: ExerciseRef) {
        self.ref = ref
        let id = ref.exerciseId
        _entries = Query(filter: #Predicate<WorkoutEntry> { $0.exerciseId == id }, sort: \.day, order: .reverse)
        _notes = Query(filter: #Predicate<Note> { $0.exerciseId == id }, sort: \.createdAt, order: .reverse)
        _settings = Query(filter: #Predicate<ExerciseSetting> { $0.exerciseId == id })
    }

    var body: some View {
        NavigationStack {
            Group {
                if let location = store.location(ofExercise: ref.exerciseId) {
                    content(location)
                } else {
                    ContentUnavailableView("Ejercicio no encontrado", systemImage: "questionmark.circle",
                                           description: Text("Este ejercicio ya no está en tu rutina."))
                }
            }
            .background(Color(.canvas))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar", systemImage: "xmark", role: .close) { dismiss() }
                }
            }
            .environment(\.openURL, OpenURLAction { url in
                guard let entry = glossary.entry(for: url) else { return .systemAction }
                glossaryEntry = entry
                return .handled
            })
            .sheet(item: $glossaryEntry) { GlossaryEntrySheet(entry: $0) }
            #if DEBUG
            .task {
                if let key = UserDefaults.standard.string(forKey: "glossary"), let url = URL(string: "\(Glossary.urlScheme)://\(key)") {
                    glossaryEntry = glossary.entry(for: url)
                }
            }
            #endif
        }
    }

    private func content(_ location: ExerciseLocation) -> some View {
        let exercise = location.exercise
        let media = MediaLibrary.details(for: exercise.gifId)

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                demo(exercise)

                VStack(alignment: .leading, spacing: 6) {
                    Text(location.block.isExtra ? "Extra · \(location.block.name)" : location.block.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(location.block.isExtra ? Color(.lavender) : Color.accentColor)
                    Text(exercise.name)
                        .font(.largeTitle.bold())
                    if let media, media.name != exercise.name {
                        Text(media.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                prescriptionGrid(exercise)

                if let notes = exercise.notes, !notes.isEmpty, notes != "." {
                    section("Indicaciones del coach", systemImage: "quote.bubble") {
                        Text(glossary.linkified(notes))
                    }
                }

                if let description = media?.description {
                    section("Descripción", systemImage: "text.alignleft") {
                        Text(glossary.linkified(description))
                    }
                }

                weightSection(exercise)

                section("Cómo hacerlo", systemImage: "list.number") {
                    if let steps = media?.instructions, !steps.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(steps.enumerated(), id: \.offset) { index, step in
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text(index + 1, format: .number)
                                        .font(.subheadline.bold())
                                        .frame(width: 24, height: 24)
                                        .background(Color(.surfaceRaised), in: .circle)
                                    Text(glossary.linkified(step))
                                }
                            }
                        }
                        if let media {
                            muscleChips(media)
                        }
                    } else {
                        Text("No hay instrucciones para este ejercicio porque no tiene un GIF asociado en ExerciseGymGifsDB ni una entrada en el catálogo de Chalk. Sigue las indicaciones de tu coach.")
                            .foregroundStyle(.secondary)
                    }
                }

                historySection

                section("Notas", systemImage: "note.text") {
                    if notes.isEmpty {
                        Text("Aún no tienes notas de este ejercicio.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(notes) { note in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.day, format: .dateTime.day().month().year())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(note.text)
                        }
                    }
                    Button("Agregar nota", systemImage: "square.and.pencil") { isAddingNote = true }
                        .buttonStyle(.glass)
                }
            }
            .padding()
        }
        .sheet(isPresented: $isAddingNote) {
            NoteEditorSheet(title: exercise.name) { text in
                WorkoutLogger(context: context).addNote(text, exerciseId: exercise.id, on: ref.day ?? Calendar.chalk.startOfDay(for: .now))
            }
        }
    }

    @ViewBuilder private func demo(_ exercise: RoutineExercise) -> some View {
        if let url = MediaLibrary.mediaURL(for: exercise.gifId) {
            let isIllustration = url.pathExtension.lowercased() != "gif"
            VStack(alignment: .leading, spacing: 8) {
                AnimatedGIFView(url: url, animates: !reduceMotion)
                    .aspectRatio(isIllustration ? 1.4 : 1, contentMode: .fit)
                    .padding(isIllustration ? 16 : 0)
                    .frame(maxWidth: .infinity)
                    .background(.white)
                    .clipShape(.rect(cornerRadius: 28))
                    .accessibilityLabel("Demostración de \(exercise.name)")
                if let image = MediaLibrary.details(for: exercise.gifId)?.image {
                    credit(image)
                }
            }
        } else {
            ContentUnavailableView {
                Label("Sin demostración disponible", systemImage: "eye.slash")
            } description: {
                Text(exercise.gifId == nil
                     ? "Este ejercicio no tiene un GIF asociado en ExerciseGymGifsDB."
                     : "La imagen no está descargada. Corre Scripts/fetch-media.sh y vuelve a compilar.")
            }
            .frame(maxWidth: .infinity, minHeight: 240)
            .background(Color(.surface), in: .rect(cornerRadius: 28))
        }
    }

    private func credit(_ image: CatalogImage) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let caption = image.caption {
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Group {
                if let source = image.sourceUrl.flatMap(URL.init(string:)) {
                    Link("Imagen: \(image.author) · \(image.license) · \(source.host() ?? "fuente")", destination: source)
                } else {
                    Text("Imagen: \(image.author) · \(image.license)")
                }
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 4)
    }

    private func prescriptionGrid(_ exercise: RoutineExercise) -> some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                stat("Series", "\(exercise.sets)")
                stat("Repeticiones", exercise.reps)
            }
            GridRow {
                stat("RIR", exercise.rir ?? "—")
                stat("Descanso", exercise.rest ?? "—")
            }
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(glossary.linkified(title))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.surface), in: .rect(cornerRadius: 18))
    }

    private func weightSection(_ exercise: RoutineExercise) -> some View {
        let current = settings.first.map(\.defaultWeightKg) ?? exercise.defaultWeightKg
        return section("Peso por defecto", systemImage: "scalemass") {
            HStack {
                Text(current.map { "\($0.formatted(.number.precision(.fractionLength(0...1)))) kg" } ?? "Sin definir")
                    .font(.title2.bold())
                    .monospacedDigit()
                Spacer()
                Button("Cambiar") { isEditingWeight = true }
                    .buttonStyle(.glass)
                    .popover(isPresented: $isEditingWeight) {
                        WeightEditor(initial: current) { kg in
                            WorkoutLogger(context: context).setWeight(kg, for: exercise, on: ref.day ?? Calendar.chalk.startOfDay(for: .now))
                        }
                        .presentationCompactAdaptation(.popover)
                    }
            }
            Text(settings.isEmpty ? "Tomado de tu rutina." : "Lo cambiaste en la app; este es el nuevo default.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var historySection: some View {
        let done = entries.filter { $0.status == .done }
        let weighted = done.filter { $0.weightKg != nil }.prefix(12).reversed()
        section("Historial", systemImage: "clock.arrow.circlepath") {
            if done.isEmpty {
                Text("Todavía no has registrado este ejercicio.")
                    .foregroundStyle(.secondary)
            } else {
                if weighted.count > 1 {
                    Chart(Array(weighted)) { entry in
                        LineMark(x: .value("Fecha", entry.day), y: .value("Peso", entry.weightKg ?? 0))
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("Fecha", entry.day), y: .value("Peso", entry.weightKg ?? 0))
                    }
                    .foregroundStyle(Color.accentColor)
                    .frame(height: 140)
                }
                ForEach(done.prefix(5)) { entry in
                    HStack {
                        Text(entry.day, format: .dateTime.weekday(.abbreviated).day().month())
                        Spacer()
                        Text(entry.weightKg.map { "\($0.formatted(.number.precision(.fractionLength(0...1)))) kg" } ?? "Sin peso")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func muscleChips(_ media: ExerciseMediaDetails) -> some View {
        let chips = [MediaLibrary.muscleName(media.muscle)]
            + (media.secondaryMuscles ?? []).map(MediaLibrary.muscleName)
            + (media.equipment.map { [MediaLibrary.equipmentName($0)] } ?? [])
        return ScrollView(.horizontal) {
            HStack {
                ForEach(chips, id: \.self) { chip in
                    Text(chip)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.surfaceRaised), in: .capsule)
                }
            }
        }
        .scrollIndicators(.hidden)
        .padding(.top, 4)
    }

    private func section<Content: View>(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
