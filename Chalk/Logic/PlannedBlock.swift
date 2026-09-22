import Foundation

/// Un bloque que se muestra en "Mi día".
struct PlannedBlock: Identifiable {
    enum Kind {
        case scheduled
        case makeup
        case extra
    }

    let block: RoutineBlock
    let kind: Kind
    /// Solo extras: sesiones completadas esta semana (incluido el día) y cuota semanal.
    var extraDone = 0
    var extraQuota = 0
    /// Solo extras: hay sesiones pendientes de días anteriores de la semana.
    var isCarriedOver = false

    var id: String { block.id }
}
