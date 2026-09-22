import Foundation

extension Calendar {
    /// Calendario de la app: semana de lunes a domingo, en español.
    static let chalk: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "es_MX")
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }()

    func startOfWeek(for date: Date) -> Date {
        dateInterval(of: .weekOfYear, for: date)?.start ?? startOfDay(for: date)
    }

    func addingDays(_ days: Int, to date: Date) -> Date {
        self.date(byAdding: .day, value: days, to: date) ?? date
    }

    /// Días desde `start` (incluido) hasta `end` (excluido).
    func days(from start: Date, to end: Date) -> [Date] {
        var result: [Date] = []
        var day = startOfDay(for: start)
        let limit = startOfDay(for: end)
        while day < limit {
            result.append(day)
            day = addingDays(1, to: day)
        }
        return result
    }
}
