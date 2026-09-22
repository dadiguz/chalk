import SwiftUI

/// Compara dos fotos con un deslizador o lado a lado.
struct PhotoCompareView: View {
    let before: ProgressPhoto
    let after: ProgressPhoto

    enum Mode: String, CaseIterable {
        case slider = "Deslizar"
        case sideBySide = "Lado a lado"
    }

    @State private var mode = Mode.slider
    @State private var reveal = 0.5

    var body: some View {
        VStack(spacing: 16) {
            Picker("Modo", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)

            switch mode {
            case .slider:
                ZStack {
                    photo(before)
                    photo(after)
                        .mask(alignment: .leading) {
                            Rectangle().scaleEffect(x: reveal, y: 1, anchor: .leading)
                        }
                }
                .aspectRatio(3 / 4, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 24))
                .overlay(alignment: .top) { labels }

                Slider(value: $reveal, in: 0...1)
                    .accessibilityLabel("Porcentaje de la foto más reciente")
            case .sideBySide:
                HStack(spacing: 8) {
                    captioned(before)
                    captioned(after)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(.canvas))
        .navigationTitle("Comparar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var labels: some View {
        HStack {
            dateTag(after.date)
            Spacer()
            dateTag(before.date)
        }
        .padding(10)
    }

    private func dateTag(_ date: Date) -> some View {
        Text(date, format: .dateTime.day().month(.abbreviated).year())
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .glassEffect(in: .capsule)
    }

    private func photo(_ photo: ProgressPhoto) -> some View {
        Color(.surface)
            .overlay {
                if let image = PhotoStorage.image(for: photo.fileName) {
                    Image(uiImage: image).resizable().scaledToFill()
                }
            }
            .clipped()
    }

    private func captioned(_ item: ProgressPhoto) -> some View {
        VStack(spacing: 6) {
            photo(item)
                .aspectRatio(3 / 4, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 18))
            Text(item.date, format: .dateTime.day().month(.abbreviated).year())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
