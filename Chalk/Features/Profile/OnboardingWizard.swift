import SwiftData
import SwiftUI

/// Primera apertura: nombre, peso y foto opcional.
struct OnboardingWizard: View {
    @Environment(\.modelContext) private var context
    @State private var step = 0
    @State private var name = ""
    @State private var weight: Double?
    @State private var photo: Data?
    @State private var errorMessage: String?
    @State private var isShowingError = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ProgressView(value: Double(step + 1), total: 3)
                    .tint(Color.accentColor)

                Group {
                    switch step {
                    case 0: nameStep
                    case 1: weightStep
                    default: photoStep
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .transition(.push(from: .trailing))

                HStack {
                    if step > 0 {
                        Button("Atrás") { withAnimation { step -= 1 } }
                            .buttonStyle(.glass)
                            .controlSize(.large)
                    }
                    Spacer()
                    Button(step == 2 ? "Empezar" : "Siguiente") { advance() }
                        .buttonStyle(.glassProminent)
                        .controlSize(.large)
                        .disabled(!canAdvance)
                }
            }
            .padding(24)
            .background(Color(.canvas))
            .alert("No se pudo guardar", isPresented: $isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .interactiveDismissDisabled()
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color(.lime).gradient)
            Text("Bienvenido a Chalk")
                .font(.largeTitle.bold())
            Text("Vamos a preparar tu perfil. ¿Cómo te llamas?")
                .foregroundStyle(.secondary)
            TextField("Tu nombre", text: $name)
                .textContentType(.givenName)
                .font(.title2)
                .padding()
                .background(Color(.surface), in: .rect(cornerRadius: 16))
                .focused($isFocused)
                .onAppear { isFocused = true }
        }
    }

    private var weightStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("¿Cuánto pesas hoy?")
                .font(.largeTitle.bold())
            Text("Lo usamos para estimar calorías y para tu gráfica de progreso. Cada semana te preguntaremos si quieres actualizarlo.")
                .foregroundStyle(.secondary)
            HStack {
                TextField("Peso", value: $weight, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .font(.title.bold().monospacedDigit())
                Text("kg").foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.surface), in: .rect(cornerRadius: 16))
        }
    }

    private var photoStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tu foto de inicio")
                .font(.largeTitle.bold())
            Text("Opcional. Se guarda solo en tu teléfono para compararte más adelante.")
                .foregroundStyle(.secondary)
            PhotoField(data: $photo)
                .frame(maxWidth: .infinity)
        }
    }

    private var canAdvance: Bool {
        switch step {
        case 0: !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: (weight ?? 0) > 0
        default: true
        }
    }

    private func advance() {
        guard step == 2 else {
            withAnimation { step += 1 }
            return
        }
        do {
            context.insert(UserProfile(name: name.trimmingCharacters(in: .whitespaces)))
            try ProfileWriter(context: context).record(weightKg: weight, photoData: photo)
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
}
