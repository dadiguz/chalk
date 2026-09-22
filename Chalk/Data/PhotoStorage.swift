import SwiftUI

/// Guarda fotos de progreso en Documents/photos como JPEG reducido.
enum PhotoStorage {
    private static var folder: URL { URL.documentsDirectory.appending(path: "photos") }

    static func url(for fileName: String) -> URL { folder.appending(path: fileName) }

    static func save(_ data: Data) throws -> String {
        guard let image = UIImage(data: data) else { throw PhotoStorageError.invalidImage }
        let resized = image.resized(maxDimension: 1600)
        guard let jpeg = resized.jpegData(compressionQuality: 0.85) else { throw PhotoStorageError.invalidImage }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let fileName = "\(UUID().uuidString).jpg"
        try jpeg.write(to: url(for: fileName), options: .atomic)
        return fileName
    }

    static func delete(_ fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    static func image(for fileName: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: fileName).path)
    }
}

enum PhotoStorageError: LocalizedError {
    case invalidImage

    var errorDescription: String? { "No se pudo leer la imagen seleccionada." }
}

private extension UIImage {
    func resized(maxDimension: Double) -> UIImage {
        let largest = max(size.width, size.height)
        guard largest > maxDimension else { return self }
        let scale = maxDimension / largest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        return UIGraphicsImageRenderer(size: target).image { _ in draw(in: CGRect(origin: .zero, size: target)) }
    }
}
