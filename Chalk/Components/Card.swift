import SwiftUI

extension View {
    /// Tarjeta de superficie con esquinas continuas, como las secciones de "Mi día".
    func card(tint: Color? = nil) -> some View {
        padding(18)
            .background(Color(.surface), in: .rect(cornerRadius: 26))
            .overlay {
                if let tint {
                    RoundedRectangle(cornerRadius: 26)
                        .strokeBorder(tint.opacity(0.55), lineWidth: 1.5)
                }
            }
    }
}
