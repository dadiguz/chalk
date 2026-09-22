import SwiftUI

/// Editor de peso en kg. Al guardar se vuelve el peso por defecto del ejercicio.
struct WeightEditor: View {
    @State private var value: Double?
    @FocusState private var isFocused: Bool
    let onSave: (Double?) -> Void
    @Environment(\.dismiss) private var dismiss

    init(initial: Double?, onSave: @escaping (Double?) -> Void) {
        _value = State(initialValue: initial)
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Peso de trabajo")
                .font(.headline)

            HStack {
                Button("Restar 2.5 kg", systemImage: "minus") { adjust(-2.5) }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)

                TextField("kg", value: $value, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.title2.bold().monospacedDigit())
                    .focused($isFocused)
                    .frame(minWidth: 90)

                Text("kg").foregroundStyle(.secondary)

                Button("Sumar 2.5 kg", systemImage: "plus") { adjust(2.5) }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
            }

            Text("Se guarda como tu nuevo peso por defecto para este ejercicio.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                if value != nil {
                    Button("Quitar", role: .destructive) { save(nil) }
                }
                Spacer()
                Button("Guardar") { save(value) }
                    .buttonStyle(.glassProminent)
            }
        }
        .padding(20)
        .frame(width: 320)
        .onAppear { isFocused = value == nil }
    }

    private func adjust(_ delta: Double) {
        value = max(0, (value ?? 0) + delta)
    }

    private func save(_ kg: Double?) {
        onSave(kg)
        dismiss()
    }
}
