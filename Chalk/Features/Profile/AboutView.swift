import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chalk")
                        .font(.title.bold())
                    Text("App personal y de código abierto para dar seguimiento a tu rutina de gimnasio. Todo se guarda solo en tu teléfono.")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                if let url = URL(string: "https://github.com/dadiguz/chalk") {
                    Link(destination: url) {
                        Label("Código fuente en GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }

            Section("Créditos") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("GIFs e instrucciones de ejercicios")
                        .font(.headline)
                    Text("Provienen de ExerciseGymGifsDB, creado por Jahel Cuadrado. Los GIFs pertenecen a sus respectivos autores; ni ExerciseGymGifsDB ni Chalk poseen derechos sobre ellos.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                if let url = URL(string: "https://github.com/JahelCuadrado/ExerciseGymGifsDB") {
                    Link(destination: url) {
                        Label("ExerciseGymGifsDB", systemImage: "arrow.up.right.square")
                    }
                }
            }

            Section("Estimación de calorías") {
                Text("Las calorías son una aproximación con MET 5.0 de entrenamiento de fuerza × tu peso corporal × el tiempo estimado (series × (45 s + descanso)). No es una medición.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Acerca de")
    }
}
