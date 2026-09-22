import SwiftUI

struct DayNotesSection: View {
    let notes: [Note]
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !notes.isEmpty {
                Text("Notas del día")
                    .font(.headline)
                ForEach(notes) { note in
                    Text(note.text)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(.surfaceRaised).opacity(0.5), in: .rect(cornerRadius: 14))
                }
            }
            Button("Agregar nota del día", systemImage: "square.and.pencil", action: onAdd)
                .buttonStyle(.glass)
                .frame(maxWidth: .infinity)
        }
    }
}
