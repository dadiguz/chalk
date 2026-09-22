import Foundation
import Testing
@testable import Chalk

@MainActor
struct GlossaryTests {
    let glossary = Glossary(meta: RoutineMeta(athlete: "T", startDate: nil, goal: nil, generalNotes: [],
                                              glossary: [GlossaryTerm(term: "Superserie", description: "Dos ejercicios seguidos.")]))

    func links(_ text: String) -> [(String, String)] {
        let attributed = glossary.linkified(text)
        return attributed.runs.compactMap { run in
            run.link.map { (String(attributed[run.range].characters), $0.host() ?? "") }
        }
    }

    @Test func linksKeywordsIgnoringCaseAndAccents() {
        let found = links("ROM completo, fase excentrica controlada. Última serie MYOreps.")
        #expect(found.map(\.1) == ["rom", "eccentric", "myoreps"])
        #expect(found[1].0 == "fase excentrica")
    }

    @Test func prefersLongestMatchAndWholeWords() {
        // "romper" no debe enlazar ROM; "fase excéntrica" gana sobre "excéntrica".
        let found = links("Sin romper la fase excéntrica.")
        #expect(found.map(\.1) == ["eccentric"])
    }

    @Test func coachTermsAreLinked() {
        #expect(links("Hacer en superserie").map(\.1) == ["coach-superserie"])
    }

    @Test func resolvesEntryFromURL() throws {
        let url = try #require(URL(string: "chalk-glossary://rir"))
        #expect(glossary.entry(for: url)?.title.hasPrefix("RIR") == true)
    }
}
