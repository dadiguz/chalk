import SwiftUI

/// Guía: cómo leer la rutina, lo que definió tu coach y cómo funciona la app.
struct GuideView: View {
    @Environment(RoutineStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private enum GuideSection: String, CaseIterable {
        case training = "Rutina"
        case coach = "Tu coach"
        case app = "La app"
    }

    @State private var section = GuideSection.training

    var body: some View {
        NavigationStack {
            List {
                Picker("Sección", selection: $section) {
                    ForEach(GuideSection.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                switch section {
                case .training: topics(GuideTopic.training)
                case .coach: coach
                case .app: topics(GuideTopic.app)
                }
            }
            .navigationTitle("Guía")
            #if DEBUG
            .task {
                if let raw = UserDefaults.standard.string(forKey: "guide"), let debug = GuideSection(rawValue: raw) { section = debug }
            }
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar", systemImage: "xmark", role: .close) { dismiss() }
                }
            }
        }
    }

    private func topics(_ items: [GuideTopic]) -> some View {
        ForEach(items) { topic in
            DisclosureGroup {
                Text(topic.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } label: {
                Label(topic.title, systemImage: topic.systemImage)
                    .font(.headline)
            }
        }
    }

    @ViewBuilder private var coach: some View {
        let meta = store.routine.meta

        if let goal = meta.goal, !goal.isEmpty {
            Section("Objetivo") { Text(goal) }
        }

        if !meta.generalNotes.isEmpty {
            Section("Indicaciones generales") {
                ForEach(meta.generalNotes, id: \.self) { Text($0).font(.subheadline) }
            }
        }

        if let scale = meta.effortScale {
            Section {
                ForEach(scale.levels) { level in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(level.value)
                            .font(.headline.monospacedDigit())
                            .frame(minWidth: 44)
                            .padding(.vertical, 4)
                            .background(Color(.lime).opacity(0.35), in: .capsule)
                        Text(level.description)
                            .font(.subheadline)
                    }
                }
            } header: {
                Text(scale.name)
            } footer: {
                if let description = scale.description { Text(description) }
            }
        }

        if !meta.glossary.isEmpty {
            Section("Términos") {
                ForEach(meta.glossary) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.term).font(.headline)
                        Text(item.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }

        if meta.generalNotes.isEmpty && meta.effortScale == nil && meta.glossary.isEmpty && (meta.goal ?? "").isEmpty {
            ContentUnavailableView("Sin notas del coach", systemImage: "person.badge.clock",
                                   description: Text("Tu rutina no incluye indicaciones generales ni escalas de esfuerzo."))
        }
    }
}
