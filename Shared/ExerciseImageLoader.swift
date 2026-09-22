import ImageIO
import UIKit

/// Carga la miniatura (primer cuadro) de un GIF o imagen del bundle de la app.
/// Funciona desde la app y desde la extensión, que vive dentro de `Chalk.app/PlugIns/`.
nonisolated enum ExerciseImageLoader {
    static var appBundleURL: URL {
        let main = Bundle.main.bundleURL
        return main.pathExtension == "appex"
            ? main.deletingLastPathComponent().deletingLastPathComponent()
            : main
    }

    static func thumbnail(relativePath: String?, maxPixelSize: Int = 160) -> UIImage? {
        guard let relativePath else { return nil }
        let url = appBundleURL.appending(path: relativePath)
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }
}
