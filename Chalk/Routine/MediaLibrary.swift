import Foundation

/// Acceso a los GIFs e instrucciones descargados con `Scripts/fetch-media.sh`.
enum MediaLibrary {
    private static let root = Bundle.main.resourceURL?.appending(path: "Routine/media")
    private static var detailsCache: [String: ExerciseMediaDetails] = [:]

    static func gifURL(for gifId: String?) -> URL? {
        guard let gifId, let url = root?.appending(path: "\(gifId).gif"),
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    static func details(for gifId: String?) -> ExerciseMediaDetails? {
        guard let gifId else { return nil }
        if let cached = detailsCache[gifId] { return cached }
        guard let url = root?.appending(path: "\(gifId).json"),
              let data = try? Data(contentsOf: url),
              let details = try? JSONDecoder().decode(ExerciseMediaDetails.self, from: data) else { return nil }
        detailsCache[gifId] = details
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
