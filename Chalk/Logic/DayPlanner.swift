import Foundation

/// Reglas de negocio de la rutina: qué toca cada día, extras pendientes, reposiciones y racha.
struct DayPlanner {
    let store: RoutineStore
    let index: EntryIndex
    private let makeupsByDay: [Date: [String]]
    private let calendar = Calendar.chalk

    init(store: RoutineStore, entries: [WorkoutEntry], makeups: [MakeupSession]) {
        self.store = store
        self.index = EntryIndex(entries: entries)
        var grouped: [Date: [String]] = [:]
        for makeup in makeups.sorted(by: { $0.createdAt < $1.createdAt }) {
            grouped[makeup.day, default: []].append(makeup.blockId)
        }
        makeupsByDay = grouped
    }

    // MARK: Días de rutina

    func makeupBlocks(on day: Date) -> [RoutineBlock] {
        (makeupsByDay[day] ?? []).compactMap { store.block(id: $0) }
    }

    /// Días de rutina (programados + repuestos) de una fecha.
    func mainBlocks(on day: Date) -> [PlannedBlock] {
        let scheduled = store.scheduledDays(on: Weekday(date: day, calendar: calendar))
        let scheduledIds = Set(scheduled.map(\.id))
        let makeups = makeupBlocks(on: day).filter { !scheduledIds.contains($0.id) }
        return scheduled.map { PlannedBlock(block: $0, kind: .scheduled) }
            + makeups.map { PlannedBlock(block: $0, kind: .makeup) }
    }

    /// Un día sin días de rutina en el calendario semanal (se puede reponer).
    func isFreeDay(_ day: Date) -> Bool {
        store.scheduledDays(on: Weekday(date: day, calendar: calendar)).isEmpty
    }

    // MARK: Extras

    func extras(on day: Date) -> [PlannedBlock] {
        let weekStart = calendar.startOfWeek(for: day)
        let previousDays = calendar.days(from: weekStart, to: day)

        return store.routine.extras.compactMap { extra in
            let quota = extra.timesPerWeek ?? 1
            let scheduledToday = store.isExtra(extra, scheduledOn: Weekday(date: day, calendar: calendar))
            let completedToday = index.isComplete(extra, on: day)
            let completedBefore = previousDays.count(where: { index.isComplete(extra, on: $0) })
            let scheduledBefore = previousDays.count(where: {
                store.isExtra(extra, scheduledOn: Weekday(date: $0, calendar: calendar))
            })
            let owed = min(scheduledBefore, quota) - completedBefore

            guard completedToday || (completedBefore < quota && (scheduledToday || owed > 0)) else { return nil }
            return PlannedBlock(
                block: extra,
                kind: .extra,
                extraDone: completedBefore + (completedToday ? 1 : 0),
                extraQuota: quota,
                isCarriedOver: owed > 0
            )
        }
    }

    func plan(for day: Date) -> [PlannedBlock] {
        mainBlocks(on: day) + extras(on: day)
    }

    // MARK: Semana

    /// Días de rutina de la semana y si ya se hicieron (programados o repuestos).
    func weekDayStatus(for day: Date) -> [(block: RoutineBlock, done: Bool)] {
        let weekStart = calendar.startOfWeek(for: day)
        let week = (0..<7).map { calendar.addingDays($0, to: weekStart) }
        return store.routine.days.map { block in
            let done = week.contains { index.doneCount(of: block, on: $0) > 0 && mainBlocks(on: $0).contains { $0.block.id == block.id } }
            return (block, done)
        }
    }

    /// Ejercicios de rutina hechos en la semana contra los programados en el calendario.
    func weekProgress(for day: Date) -> (done: Int, total: Int) {
        let weekStart = calendar.startOfWeek(for: day)
        var done = 0
        var total = 0
        for offset in 0..<7 {
            let date = calendar.addingDays(offset, to: weekStart)
            total += store.scheduledDays(on: Weekday(date: date, calendar: calendar)).reduce(0) { $0 + $1.exercises.count }
            done += mainBlocks(on: date).reduce(0) { $0 + index.doneCount(of: $1.block, on: date) }
        }
        return (min(done, total), total)
    }

    /// Extras completados en la semana contra la suma de cuotas.
    func weekExtrasProgress(for day: Date) -> (done: Int, total: Int) {
        let weekStart = calendar.startOfWeek(for: day)
        let week = (0..<7).map { calendar.addingDays($0, to: weekStart) }
        var done = 0
        var total = 0
        for extra in store.routine.extras {
            let quota = extra.timesPerWeek ?? 1
            total += quota
            done += min(week.count(where: { index.isComplete(extra, on: $0) }), quota)
        }
        return (done, total)
    }

    // MARK: Racha

    /// Días consecutivos con al menos un ejercicio hecho. Los días libres sin actividad no la rompen,
    /// y hoy no la rompe mientras siga en curso.
    func streak(today: Date) -> Int {
        guard let earliest = index.earliestDay else { return 0 }
        var count = index.hasAnyDone(on: today) ? 1 : 0
        var day = calendar.addingDays(-1, to: today)
        while day >= earliest {
            if index.hasAnyDone(on: day) {
                count += 1
            } else if !mainBlocks(on: day).isEmpty {
                break
            }
            day = calendar.addingDays(-1, to: day)
        }
        return count
    }

    /// Días de rutina de ayer que no tuvieron ningún ejercicio hecho y no se han repuesto.
    func missedYesterday(today: Date) -> [RoutineBlock] {
        let yesterday = calendar.addingDays(-1, to: today)
        let madeUpLater = Set(calendar.days(from: today, to: calendar.addingDays(7, to: today)).flatMap { makeupBlocks(on: $0).map(\.id) })
        return mainBlocks(on: yesterday)
            .filter { index.doneCount(of: $0.block, on: yesterday) == 0 && !madeUpLater.contains($0.block.id) }
            .map(\.block)
    }
}
