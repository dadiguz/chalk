import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var createdAt: Date
    var lastCheckInAt: Date
    var lastPromptAt: Date?

    init(name: String) {
        self.name = name
        self.createdAt = .now
        self.lastCheckInAt = .now
    }

    /// Pregunta cada 7 días y, si dices "ahora no", vuelve a preguntar al día siguiente.
    func needsWeeklyCheckIn(now: Date = .now) -> Bool {
        let week: TimeInterval = 7 * 24 * 3600
        guard now.timeIntervalSince(lastCheckInAt) >= week else { return false }
        guard let lastPromptAt else { return true }
        return now.timeIntervalSince(lastPromptAt) >= 24 * 3600
    }
}
