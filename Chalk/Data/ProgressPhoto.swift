import Foundation
import SwiftData

/// Foto de progreso. La imagen vive en Documents/photos; aquí solo el nombre del archivo.
@Model
final class ProgressPhoto {
    var date: Date
    var fileName: String

    init(date: Date = .now, fileName: String) {
        self.date = date
        self.fileName = fileName
    }
}
