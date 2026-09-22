import Foundation

struct GlossaryTerm: Codable, Sendable, Hashable, Identifiable {
    let term: String
    let description: String

    var id: String { term }
}
