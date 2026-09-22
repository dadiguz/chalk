import Foundation

struct RoutineMeta: Codable, Sendable {
    let athlete: String
    let startDate: String?
    let goal: String?
    let generalNotes: [String]
    /// Términos que define el coach (por ejemplo "MYOreps"). Opcional.
    let glossary: [GlossaryTerm]
    /// Escala de esfuerzo que trae la rutina (por ejemplo RPE 1–10). Opcional.
    let effortScale: EffortScale?

    init(athlete: String, startDate: String?, goal: String?, generalNotes: [String],
         glossary: [GlossaryTerm] = [], effortScale: EffortScale? = nil) {
        self.athlete = athlete
        self.startDate = startDate
        self.goal = goal
        self.generalNotes = generalNotes
        self.glossary = glossary
        self.effortScale = effortScale
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        athlete = try container.decode(String.self, forKey: .athlete)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        goal = try container.decodeIfPresent(String.self, forKey: .goal)
        generalNotes = try container.decodeIfPresent([String].self, forKey: .generalNotes) ?? []
        glossary = try container.decodeIfPresent([GlossaryTerm].self, forKey: .glossary) ?? []
        effortScale = try container.decodeIfPresent(EffortScale.self, forKey: .effortScale)
    }
}
