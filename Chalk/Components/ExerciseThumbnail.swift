import SwiftUI

/// Primer cuadro del GIF, o un marcador claro cuando el ejercicio no tiene GIF.
struct ExerciseThumbnail: View {
    let gifId: String?
    var size = 56.0

    var body: some View {
        Group {
            if let url = MediaLibrary.mediaURL(for: gifId), let image = GIFDecoder.thumbnail(at: url) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .background(.white)
            } else {
                ZStack {
                    Color(.surfaceRaised)
                    VStack(spacing: 4) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: size * 0.4))
                        if size >= 90 {
                            Text("Sin GIF")
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Sin GIF")
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: size * 0.22))
    }
}
