import SwiftUI

/// Glosario enlazable: temas de entrenamiento de la guía + términos que define el coach en la rutina.
struct Glossary {
    static let urlScheme = "chalk-glossary"

    let entries: [GuideTopic]

    init(meta: RoutineMeta) {
        let coach = meta.glossary.map { term in
            GuideTopic(key: "coach-\(Self.slug(term.term))", title: term.term, systemImage: "person.fill.questionmark",
                       body: term.description, keywords: [term.term])
        }
        // Los términos del coach van primero: si coinciden con uno de la guía, manda la definición del coach.
        entries = coach + GuideTopic.training
    }

    func entry(for url: URL) -> GuideTopic? {
        guard url.scheme == Self.urlScheme, let key = url.host() else { return nil }
        return entries.first { $0.key == key }
    }

    /// Convierte en enlaces las palabras clave del glosario que aparezcan en el texto.
    /// Busca sin distinguir mayúsculas ni acentos, solo palabras completas, y prefiere la coincidencia más larga.
    func linkified(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        let keywords = entries
            .flatMap { entry in entry.keywords.map { (keyword: $0, key: entry.key) } }
            .sorted { $0.keyword.count > $1.keyword.count }
        var taken: [Range<String.Index>] = []

        for (keyword, key) in keywords {
            var searchRange = text.startIndex..<text.endIndex
            while let found = text.range(of: keyword, options: [.caseInsensitive, .diacriticInsensitive], range: searchRange) {
                searchRange = found.upperBound..<text.endIndex
                guard isWholeWord(found, in: text), !taken.contains(where: { $0.overlaps(found) }),
                      let attributedRange = Range(found, in: result),
                      let url = URL(string: "\(Self.urlScheme)://\(key)") else { continue }
                taken.append(found)
                result[attributedRange].link = url
                result[attributedRange].underlineStyle = .single
            }
        }
        return result
    }

    private func isWholeWord(_ range: Range<String.Index>, in text: String) -> Bool {
        let before = range.lowerBound > text.startIndex ? text[text.index(before: range.lowerBound)] : " "
        let after = range.upperBound < text.endIndex ? text[range.upperBound] : " "
        return !before.isLetter && !after.isLetter
    }

    private static func slug(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .map { $0.isLetter || $0.isNumber ? $0 : "-" }
            .reduce(into: "") { $0.append($1) }
    }
}
