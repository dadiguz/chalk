import Foundation
import SwiftData

/// Guarda peso corporal y fotos de progreso.
struct ProfileWriter {
    let context: ModelContext

    func record(weightKg: Double?, photoData: Data?, date: Date = .now) throws {
        if let weightKg, weightKg > 0 {
            context.insert(BodyWeightEntry(date: date, kg: weightKg))
        }
        if let photoData {
            let fileName = try PhotoStorage.save(photoData)
            context.insert(ProgressPhoto(date: date, fileName: fileName))
        }
    }
}
