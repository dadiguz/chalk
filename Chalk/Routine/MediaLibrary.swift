import Foundation

/// Acceso a la media de cada ejercicio: GIFs de ExerciseGymGifsDB descargados con
/// `Scripts/fetch-media.sh`, o imágenes del catálogo propio (`Catalog/`).
enum MediaLibrary {
    private static let mediaRoot = Bundle.main.resourceURL?.appending(path: "Routine/media")
    private static let catalogRoot = Bundle.main.resourceURL?.appending(path: "Catalog")
    private static var detailsCache: [String: ExerciseMediaDetails] = [:]

    private static let catalog: [String: ExerciseMediaDetails] = {
        guard let url = catalogRoot?.appending(path: "exercises.json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(ExerciseCatalog.self, from: data) else { return [:] }
        return Dictionary(catalog.exercises.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }()

    static func isCatalog(_ mediaId: String?) -> Bool {
        mediaId?.hasPrefix(ExerciseCatalog.idPrefix) ?? false
    }

    /// GIF animado de ExerciseGymGifsDB, si está descargado.
    static func gifURL(for mediaId: String?) -> URL? {
        guard let mediaId, !isCatalog(mediaId), let url = mediaRoot?.appending(path: "\(mediaId).gif"),
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    /// Imagen a mostrar: el GIF o, para el catálogo propio, su imagen fija.
    static func mediaURL(for mediaId: String?) -> URL? {
        if let gif = gifURL(for: mediaId) { return gif }
        guard let file = details(for: mediaId)?.image?.file,
              let url = catalogRoot?.appending(path: "images/\(file)"),
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    /// Ruta de la media relativa al bundle de la app, para que la Live Activity la lea.
    static func bundleRelativeMediaPath(for mediaId: String?) -> String? {
        guard let url = mediaURL(for: mediaId) else { return nil }
        let base = Bundle.main.bundleURL.standardizedFileURL.path + "/"
        let path = url.standardizedFileURL.path
        return path.hasPrefix(base) ? String(path.dropFirst(base.count)) : nil
    }

    static func details(for mediaId: String?) -> ExerciseMediaDetails? {
        guard let mediaId else { return nil }
        if isCatalog(mediaId) { return catalog[mediaId] }
        if let cached = detailsCache[mediaId] { return cached }
        guard let url = mediaRoot?.appending(path: "\(mediaId).json"),
              let data = try? Data(contentsOf: url),
              let details = try? JSONDecoder().decode(ExerciseMediaDetails.self, from: data) else { return nil }
        detailsCache[mediaId] = details
        return details
    }

    static let muscleNames: [String: String] = [
        "abductors": "Abductores", "abs": "Abdomen", "adductors": "Aductores", "biceps": "Bíceps",
        "calves": "Pantorrillas", "cardio": "Cardio", "delts": "Deltoides", "forearms": "Antebrazos",
        "glutes": "Glúteos", "hamstrings": "Isquiotibiales", "lats": "Dorsales",
        "levator-scapulae": "Elevador de la escápula", "pectorals": "Pectorales", "quads": "Cuádriceps",
        "serratus-anterior": "Serrato anterior", "spine": "Espalda baja", "traps": "Trapecios",
        "triceps": "Tríceps", "upper-back": "Espalda alta",
    ]

    static let equipmentNames: [String: String] = [
        "barbell": "Barra", "dumbbell": "Mancuerna", "cable": "Polea", "machine": "Máquina",
        "bodyweight": "Peso corporal", "band": "Banda", "kettlebell": "Kettlebell", "smith": "Multipower",
        "ez-bar": "Barra Z", "lever": "Máquina", "other": "Otro",
    ]

    static func muscleName(_ key: String) -> String { muscleNames[key] ?? key.capitalized }
    static func equipmentName(_ key: String) -> String { equipmentNames[key] ?? key.capitalized }
}
