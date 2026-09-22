import Foundation

/// Imagen de referencia del catálogo propio, con los datos de atribución que exige su licencia.
struct CatalogImage: Codable, Sendable, Hashable {
    let file: String
    let caption: String?
    let author: String
    let license: String
    let licenseUrl: String?
    let sourceUrl: String?
}
