import SwiftData
import SwiftUI

struct TodayView: View {
    let onOpenProfile: () -> Void

    @Environment(RoutineStore.self) private var store
    @Environment(\.modelContext) private var context
    @Query private var entries: [WorkoutEntry]
    @Query private var makeups: [MakeupSession]
    @Query private var settings: [ExerciseSetting]
    @Query(sort: \Note.createdAt) private var notes: [Note]
    @Query(sort: \BodyWeightEntry.date) private var bodyWeights: [BodyWeightEntry]
    @Query(sort: \ProgressPhoto.date, order: .reverse) private var photos: [ProgressPhoto]

    @State private var selectedDate = Calendar.chalk.startOfDay(for: .now)
    @State private var detail: ExerciseRef?
    @State private var isAddingNote = false
    @State private var isPickingMakeup = false

    private let calendar = Calendar.chalk
    private var logger: WorkoutLogger { WorkoutLogger(context: context) }
    private var isToday: Bool { selectedDate == calendar.startOfDay(for: .now) }

    var body: some View {
        let planner = DayPlanner(store: store, entries: entries, makeups: makeups)
        let plan = planner.plan(for: selectedDate)
        let mainBlocks = plan.filter { $0.kind != .extra }
        let settingsById = Dictionary(settings.map { ($0.exerciseId, $0) }, uniquingKeysWith: { first, _ in first })
        let dayNotes = notes.filter { $0.day == selectedDate }

        ScrollView {
            VStack(spacing: 16) {
                rings(planner: planner, plan: plan)

                if isToday {
                    let missed = planner.missedYesterday(today: selectedDate)
                    if !missed.isEmpty { MissedDayBanner(blocks: missed) }
                }

                if planner.isFreeDay(selectedDate) {
                    FreeDayCard(hasMakeups: !mainBlocks.isEmpty) { isPickingMakeup = true }
                }

                ForEach(plan) { planned in
                    BlockCard(
                        planned: planned,
                        day: selectedDate,
                        index: planner.index,
                        weightFor: { exercise in
                            if let setting = settingsById[exercise.id] { return setting.defaultWeightKg }
                            return exercise.defaultWeightKg
                        },
                        exercisesWithNotes: Set(notes.compactMap(\.exerciseId)),
                        onStatus: { exercise, status in
                            logger.setStatus(status, for: exercise, in: planned.block, on: selectedDate)
                        },
                        onBlockStatus: { status in
                            logger.setStatus(status, forAllIn: planned.block, on: selectedDate)
                        },
                        onWeight: { exercise, kg in
                            logger.setWeight(kg, for: exercise, on: selectedDate)
                        },
                        onOpen: { exercise in
                            detail = ExerciseRef(exerciseId: exercise.id, day: selectedDate)
                        },
                        onRemoveMakeup: planned.kind == .makeup
                            ? { logger.removeMakeup(planned.block, on: selectedDate) }
                            : nil
                    )
                }

                DayNotesSection(notes: dayNotes) { isAddingNote = true }
                    .padding(.top, 4)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .animation(.snappy, value: plan.map(\.id))
        }
        .scrollIndicators(.hidden)
        .background(Color(.canvas))
        .safeAreaInset(edge: .top, spacing: 0) {
            TodayHeader(
                streak: planner.streak(today: calendar.startOfDay(for: .now)),
                date: $selectedDate,
                avatar: photos.first.flatMap { PhotoStorage.image(for: $0.fileName) },
                onOpenProfile: onOpenProfile
            )
        }
        .simultaneousGesture(swipeBetweenDays)
        #if DEBUG
        .task {
            if let id = UserDefaults.standard.string(forKey: "detail") { detail = ExerciseRef(exerciseId: id) }
        }
        #endif
        .sheet(item: $detail) { ref in
            ExerciseDetailView(ref: ref)
        }
        .sheet(isPresented: $isAddingNote) {
            NoteEditorSheet(title: "Nota del día") { text in
                logger.addNote(text, exerciseId: nil, on: selectedDate)
            }
        }
        .sheet(isPresented: $isPickingMakeup) {
            MakeupPicker(
                options: planner.weekDayStatus(for: selectedDate),
                excluded: Set(mainBlocks.map(\.id))
            ) { block in
                logger.addMakeup(block, on: selectedDate)
            }
        }
    }

    private func rings(planner: DayPlanner, plan: [PlannedBlock]) -> some View {
        let exercises = plan.filter { $0.kind != .extra }.flatMap(\.block.exercises)
        let done = exercises.filter { planner.index.status(of: $0.id, on: selectedDate) == .done }
        let allDone = plan.flatMap(\.block.exercises).filter { planner.index.status(of: $0.id, on: selectedDate) == .done }
        let bodyWeight = CalorieEstimator.bodyWeight(on: .now, from: bodyWeights)

        return DayRingsCard(
            exercisesDone: done.count,
            exercisesTotal: exercises.count,
            week: planner.weekProgress(for: selectedDate),
            extras: planner.weekExtrasProgress(for: selectedDate),
            kcalDone: CalorieEstimator.kcal(for: allDone, bodyWeightKg: bodyWeight),
            kcalPlanned: CalorieEstimator.kcal(for: plan.flatMap(\.block.exercises), bodyWeightKg: bodyWeight)
        )
    }

    private var swipeBetweenDays: some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) * 2 else { return }
                let today = calendar.startOfDay(for: .now)
                withAnimation(.snappy) {
                    let next = calendar.addingDays(value.translation.width < 0 ? 1 : -1, to: selectedDate)
                    selectedDate = min(next, today)
                }
            }
    }
}
