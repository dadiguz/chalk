import Foundation

enum Weekday: String, CaseIterable, Identifiable, Sendable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: String { rawValue }

    init(date: Date, calendar: Calendar = .chalk) {
        // Calendar.weekday: 1 = domingo, 2 = lunes, ...
        self = switch calendar.component(.weekday, from: date) {
        case 1: .sunday
        case 2: .monday
        case 3: .tuesday
        case 4: .wednesday
        case 5: .thursday
        case 6: .friday
        default: .saturday
        }
    }

    var displayName: String {
        switch self {
        case .monday: "Lunes"
        case .tuesday: "Martes"
        case .wednesday: "Miércoles"
        case .thursday: "Jueves"
        case .friday: "Viernes"
        case .saturday: "Sábado"
        case .sunday: "Domingo"
        }
    }

    /// Posición dentro de la semana, empezando en lunes = 0.
    var offset: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}
