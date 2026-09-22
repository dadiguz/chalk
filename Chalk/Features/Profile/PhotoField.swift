import PhotosUI
import SwiftUI

/// Selector de foto con vista previa. Entrega los datos crudos de la imagen elegida.
struct PhotoField: View {
    @Binding var data: Data?
    var label = "Elegir foto"
    @State private var selection: PhotosPickerItem?

    var body: some View {
        let title = data == nil ? label : "Cambiar foto"
        VStack(spacing: 12) {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 240)
                    .clipShape(.rect(cornerRadius: 22))
            }
            PhotosPicker(selection: $selection, matching: .images) {
                Label(title, systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.glass)
        }
        .task(id: selection) {
            guard let selection else { return }
            data = try? await selection.loadTransferable(type: Data.self)
        }
    }
}
