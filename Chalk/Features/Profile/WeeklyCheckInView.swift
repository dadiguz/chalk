import SwiftData
import SwiftUI

/// Check-in semanal: actualizar peso y foto. Nunca obliga.
struct WeeklyCheckInView: View {
    let profile: UserProfile
    var isManual = false

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BodyWeightEntry.date, order: .reverse) private var weights: [BodyWeightEntry]
    @State private var weight: Double?
    @State private var photo: Data?
    @State private var errorMessage: String?
    @State private var isShowingError = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(isManual ? "Registra tu peso y una foto nueva." : "Pasó una semana. ¿Actualizamos tu peso y tu foto?")
                        .font(.headline)
                }
                Section("Peso corporal") {
                    HStack {
                        TextField("Peso", value: $weight, format: .number.precision(.fractionLength(0...1)))
                            .keyboardType(.decimalPad)
                            .font(.title2.bold().monospacedDigit())
                        Text("kg").foregroundStyle(.secondary)
                    }
                    if let last = weights.first {
                        Text("Último: \(last.kg.formatted(.number.precision(.fractionLength(0...1)))) kg el \(last.date.formatted(.dateTime.day().month()))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Foto de progreso") {
                    PhotoField(data: $photo, label: "Agregar foto")
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Ahora no") { snooze() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", systemImage: "checkmark") { save() }
                        .disabled(weight == nil && photo == nil)
                }
            }
            .onAppear { weight = weights.first?.kg }
            .alert("No se pudo guardar", isPresented: $isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func snooze() {
        if !isManual { profile.lastPromptAt = .now }
        dismiss()
    }

    private func save() {
        do {
            let newWeight = weight == weights.first?.kg && photo != nil ? nil : weight
            try ProfileWriter(context: context).record(weightKg: newWeight, photoData: photo)
            profile.lastCheckInAt = .now
            profile.lastPromptAt = .now
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
}
