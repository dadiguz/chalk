import SwiftUI

/// Semana de lunes a domingo en vertical; los ejercicios de cada día en horizontal.
struct PlanView: View {
    @Environment(RoutineStore.self) private var store
    @State private var detail: ExerciseRef?

    private var todayWeekday: Weekday { Weekday(date: .now) }

    var body: some View {
        NavigationStack {
            List {
                if store.isExample {
                    Label("Estás viendo la rutina de ejemplo. Crea la tuya siguiendo CLAUDE.md.", systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let error = store.loadError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }

                ForEach(Weekday.allCases) { weekday in
                    let blocks = store.scheduledBlocks(on: weekday)
                    Section {
                        if blocks.isEmpty {
                            Label("Libre · puedes reponer un día", systemImage: "leaf")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(blocks) { block in
                            blockRow(block)
                        }
                    } header: {
                        HStack {
                            Text(weekday.displayName)
                            if weekday == todayWeekday {
                                Text("Hoy")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .foregroundStyle(Color(.onLime))
                                    .background(Color(.lime), in: .capsule)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.canvas))
            .navigationTitle("Plan")
            .sheet(item: $detail) { ExerciseDetailView(ref: $0) }
        }
    }

    private func blockRow(_ block: RoutineBlock) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(block.title)
                    .font(.headline)
                    .foregroundStyle(block.isExtra ? Color(.lavender) : .primary)
                Spacer()
                if let times = block.timesPerWeek {
                    Text("\(times)× semana")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(block.exercises) { exercise in
                        Button {
                            detail = ExerciseRef(exerciseId: exercise.id)
                        } label: {
                            PlanExerciseCard(exercise: exercise, isExtra: block.isExtra)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
        }
        .padding(.vertical, 6)
        .listRowBackground(Color(.surface))
    }
}
