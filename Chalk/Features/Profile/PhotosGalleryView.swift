import SwiftData
import SwiftUI

struct PhotosGalleryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ProgressPhoto.date) private var photos: [ProgressPhoto]
    @State private var compared: [ProgressPhoto] = []
    @State private var isComparing = false

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 8)]

    var body: some View {
        ScrollView {
            if photos.isEmpty {
                ContentUnavailableView("Sin fotos", systemImage: "photo.on.rectangle",
                                       description: Text("Agrega fotos desde el check-in semanal para compararte."))
                    .padding(.top, 80)
            } else {
                Text("Toca dos fotos para compararlas.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(photos) { photo in
                        tile(photo)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(.canvas))
        .navigationTitle("Fotos")
        .toolbar {
            if photos.count >= 2 {
                ToolbarItem(placement: .primaryAction) {
                    Button("Comparar primera y última") {
                        compared = [photos[0], photos[photos.count - 1]]
                        isComparing = true
                    }
                }
            }
        }
        .navigationDestination(isPresented: $isComparing) {
            if compared.count == 2 {
                PhotoCompareView(before: compared[0], after: compared[1])
            }
        }
    }

    private func tile(_ photo: ProgressPhoto) -> some View {
        let isSelected = compared.contains(photo)
        return Button {
            toggle(photo)
        } label: {
            Color(.surface)
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay {
                    if let image = PhotoStorage.image(for: photo.fileName) {
                        Image(uiImage: image).resizable().scaledToFill()
                    }
                }
                .clipShape(.rect(cornerRadius: 14))
                .overlay(alignment: .bottomLeading) {
                    Text(photo.date, format: .dateTime.day().month(.abbreviated).year(.twoDigits))
                        .font(.caption2.bold())
                        .padding(6)
                        .background(.ultraThinMaterial, in: .capsule)
                        .padding(6)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color(.lime), lineWidth: isSelected ? 3 : 0)
                }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Eliminar", systemImage: "trash", role: .destructive) { delete(photo) }
        }
        .accessibilityLabel("Foto del \(photo.date.formatted(date: .long, time: .omitted))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func toggle(_ photo: ProgressPhoto) {
        if let index = compared.firstIndex(of: photo) {
            compared.remove(at: index)
            return
        }
        compared.append(photo)
        if compared.count == 2 {
            compared.sort { $0.date < $1.date }
            isComparing = true
        } else if compared.count > 2 {
            compared = [photo]
        }
    }

    private func delete(_ photo: ProgressPhoto) {
        compared.removeAll { $0 == photo }
        PhotoStorage.delete(photo.fileName)
        context.delete(photo)
    }
}
