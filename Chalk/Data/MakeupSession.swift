import Foundation
import SwiftData

/// Un día de rutina repuesto en otra fecha (por ejemplo, Día 3 hecho el sábado).
@Model
final class MakeupSession {
    var day: Date
    var blockId: String
    var createdAt: Date

    init(day: Date, blockId: String) {
        self.day = day
        self.blockId = blockId
        self.createdAt = .now
    }
}
