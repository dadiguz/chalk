import CoreText
import UIKit

/// Registra las fuentes opcionales de `Chalk/Resources/Fonts` (ignoradas por git por su licencia).
enum FontRegistry {
    static let brandFontName = "RealChalk"
    static let fallbackFontName = "Chalkduster"

    static func registerBundledFonts() {
        let urls = ["otf", "ttf"].flatMap { Bundle.main.urls(forResourcesWithExtension: $0, subdirectory: nil) ?? [] }
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    /// Nombre de la fuente de marca si está instalada; si no, Chalkduster (incluida en iOS).
    static var brandFontNameOrFallback: String {
        UIFont(name: brandFontName, size: 12) != nil ? brandFontName : fallbackFontName
    }
}
