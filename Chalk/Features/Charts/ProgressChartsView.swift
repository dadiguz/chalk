import Charts
import SwiftData
import SwiftUI

/// Cuatro gráficas: calorías estimadas, adherencia, progresión de carga y peso corporal.
struct ProgressChartsView: View {
    @Environment(RoutineStore.self) private var store
    @Query private var entries: [WorkoutEntry]
    @Query private var makeups: [MakeupSession]
    @Query(sort: \BodyWeightEntry.date) private var bodyWeights: [BodyWeightEntry]
    @Query(sort: \ProgressPhoto.date) private var photos: [ProgressPhoto]
    @State private var selectedExerciseId: String?

    private let calendar = Calendar.chalk

    var body: some View {
        let planner = DayPlanner(store: store, entries: entries, makeups: makeups)
        let stats = ProgressStats(planner: planner, store: store, entries: entries, bodyWeights: bodyWeights)
        let today = calendar.startOfDay(for: .now)

        ScrollView {
            VStack(spacing: 16) {
                caloriesChart(stats, today: today)
                adherenceChart(stats, today: today)
                loadChart(stats)
                bodyWeightChart
            }
            .padding()
        }
        .background(Color(.canvas))
        .navigationTitle("Progreso")
    }

    private func caloriesChart(_ stats: ProgressStats, today: Date) -> some View {
        let data = stats.dailyKcal(days: 14, endingOn: today)
        let week = stats.weekKcal(containing: today)
        return ChartCard(title: "Calorías estimadas",
                         subtitle: "≈ \(week.formatted(.number.precision(.fractionLength(0)))) kcal esta semana · aproximación") {
            Chart(data) { item in
                BarMark(x: .value("Día", item.day, unit: .day), y: .value("kcal", item.kcal))
                    .foregroundStyle(.orange.gradient)
                    .clipShape(.rect(cornerRadius: 4))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) {
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .frame(height: 180)
            if bodyWeights.isEmpty {
                Text("Registra tu peso en Perfil para una estimación más precisa (se usan 75 kg).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func adherenceChart(_ stats: ProgressStats, today: Date) -> some View {
        let data = stats.adherence(weeks: 8, endingOn: today)
        return ChartCard(title: "Adherencia semanal", subtitle: "Ejercicios hechos contra programados, últimas 8 semanas") {
            Chart(data) { item in
                BarMark(x: .value("Semana", item.weekStart, unit: .weekOfYear),
                        y: .value("%", item.percent))
                    .foregroundStyle(by: .value("Tipo", item.series))
                    .position(by: .value("Tipo", item.series))
                    .clipShape(.rect(cornerRadius: 4))
            }
            .chartForegroundStyleScale(["Rutina": Color(.lime), "Extras": Color(.lavender)])
            .chartYScale(domain: 0...1)
            .chartYAxis {
                AxisMarks(values: [0, 0.5, 1]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let percent = value.as(Double.self) {
                            Text(percent, format: .percent.precision(.fractionLength(0)))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 2)) {
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .frame(height: 180)
        }
    }

    @ViewBuilder private func loadChart(_ stats: ProgressStats) -> some View {
        let exercises = stats.weightedExercises
        let selected = selectedExerciseId.flatMap { id in exercises.first { $0.id == id } } ?? exercises.first
        ChartCard(title: "Progresión de carga", subtitle: "Peso registrado por sesión") {
            if let selected {
                Picker("Ejercicio", selection: $selectedExerciseId) {
                    ForEach(exercises) { Text($0.name).tag(Optional($0.id)) }
                }
                .onAppear { if selectedExerciseId == nil { selectedExerciseId = selected.id } }
                .pickerStyle(.menu)
                .tint(.primary)

                let points = stats.load(for: selected.id)
                Chart(points) { point in
                    LineMark(x: .value("Fecha", point.day), y: .value("kg", point.kg))
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Fecha", point.day), y: .value("kg", point.kg))
                }
                .foregroundStyle(Color.accentColor)
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 180)
            } else {
                Text("Registra el peso de tus ejercicios en Mi día para ver cómo subes.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var bodyWeightChart: some View {
        let photoDays = Set(photos.map { calendar.startOfDay(for: $0.date) })
        return ChartCard(title: "Peso corporal", subtitle: "Check-ins semanales · 📷 = hay foto ese día") {
            if bodyWeights.isEmpty {
                Text("Aún no hay registros de peso.")
                    .foregroundStyle(.secondary)
            } else {
                Chart(bodyWeights) { entry in
                    LineMark(x: .value("Fecha", entry.date), y: .value("kg", entry.kg))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color(.lavender))
                    PointMark(x: .value("Fecha", entry.date), y: .value("kg", entry.kg))
                        .foregroundStyle(Color(.lavender))
                        .annotation(position: .top) {
                            if photoDays.contains(calendar.startOfDay(for: entry.date)) {
                                Image(systemName: "camera.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 180)

                if photos.count >= 2 {
                    NavigationLink {
                        PhotoCompareView(before: photos[0], after: photos[photos.count - 1])
                    } label: {
                        Label("Comparar primera y última foto", systemImage: "rectangle.split.2x1")
                    }
                    .buttonStyle(.glass)
                }
            }
        }
    }
}
