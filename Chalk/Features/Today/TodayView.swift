import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(RoutineStore.self) private var store
    @Environment(\.modelContext) private var context
    @Query private var entries: [WorkoutEntry]
    @Query private var makeups: [MakeupSession]
    @Query private var settings: [ExerciseSetting]
    @Query(sort: \Note.createdAt) private var notes: [Note]
    @Query(sort: \BodyWeightEntry.date) private var bodyWeights: [BodyWeightEntry]

    @State private var selectedDate = Calendar.chalk.startOfDay(for: .now)
    @State private var detail: ExerciseRef?
    @State private var isAddingNote = false
    @State private var isPickingMakeup = false
    @State private var isShowingGuide = false
    @State private var session = WorkoutSession.shared
    @State private var isShowingSessionError = false
    #if DEBUG
    @State private var isShowingActivityPreview = false
    #endif

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

                if isToday, !plan.isEmpty {
                    sessionCard(planner: planner, plan: plan)
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
                        currentExerciseId: isToday ? session.currentExerciseId : nil,
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
                onOpenGuide: { isShowingGuide = true }
            )
        }
        .simultaneousGesture(swipeBetweenDays)
        #if DEBUG
        .task {
            if let id = UserDefaults.standard.string(forKey: "detail") { detail = ExerciseRef(exerciseId: id) }
            isShowingGuide = UserDefaults.standard.string(forKey: "guide") != nil
            if UserDefaults.standard.bool(forKey: "startWorkout"), !session.isRunning {
                await session.start(day: selectedDate)
            }
            if UserDefaults.standard.bool(forKey: "completeCurrent"), let id = session.currentExerciseId {
                // Mismo camino que el ✓ de la Live Activity (CompleteExerciseIntent).
                _ = try? await CompleteExerciseIntent(exerciseId: id).perform()
            }
            isShowingActivityPreview = UserDefaults.standard.bool(forKey: "liveActivityPreview")
        }
        #endif
        .sheet(item: $detail) { ref in
            ExerciseDetailView(ref: ref)
        }
        .onChange(of: syncSignature) {
            guard session.isRunning else { return }
            Task { await session.refresh() }
        }
        .alert("Entrenamiento", isPresented: $isShowingSessionError) {
            Button("OK", role: .cancel) { session.errorMessage = nil }
        } message: {
            Text(session.errorMessage ?? "")
        }
        .onChange(of: session.errorMessage) { _, message in
            isShowingSessionError = message != nil
        }
        #if DEBUG
        .sheet(isPresented: $isShowingActivityPreview) {
            LiveActivityPreview()
        }
        #endif
        .sheet(isPresented: $isShowingGuide) {
            GuideView()
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

    /// Cambia cuando se marca, desmarca o cambia el peso de algo; mantiene la Live Activity al día.
    private var syncSignature: [String] {
        entries.map { "\($0.day.timeIntervalSince1970)|\($0.exerciseId)|\($0.statusRaw)|\($0.weightKg ?? -1)" }.sorted()
            + makeups.map { "\($0.day.timeIntervalSince1970)|\($0.blockId)" }.sorted()
    }

    private func sessionCard(planner: DayPlanner, plan: [PlannedBlock]) -> some View {
        let queue = WorkoutQueue(plan: plan)
        let current = queue.current(index: planner.index, day: selectedDate)
        let resolved = queue.resolvedCount(index: planner.index, day: selectedDate)
        return Group {
            if current != nil || session.isRunning {
                WorkoutSessionCard(
                    session: session,
                    currentName: current?.exercise.name,
                    resolved: resolved,
                    total: queue.items.count,
                    onStart: { Task { await session.start(day: selectedDate) } },
                    onStop: { Task { await session.stop() } }
                )
            }
        }
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
