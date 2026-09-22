import SwiftUI

/// Reproduce un GIF en bucle. Respeta "Reducir movimiento" mostrando solo el primer cuadro.
struct AnimatedGIFView: UIViewRepresentable {
    let url: URL
    var animates = true

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        view.image = animates ? GIFDecoder.animatedImage(at: url) : GIFDecoder.thumbnail(at: url, maxPixelSize: 720)
    }
}
