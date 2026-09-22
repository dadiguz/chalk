import Foundation

struct RoutineMeta: Codable, Sendable {
    let athlete: String
    let startDate: String?
    let goal: String?
    let generalNotes: [String]

    init(athlete: String, startDate: String?, goal: String?, generalNotes: [String]) {
        self.athlete = athlete
        self.startDate = startDate
        self.goal = goal
        self.generalNotes = generalNotes
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        athlete = try container.decode(String.self, forKey: .athlete)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        goal = try container.decodeIfPresent(String.self, forKey: .goal)
        generalNotes = try container.decodeIfPresent([String].self, forKey: .generalNotes) ?? []
    }
}
