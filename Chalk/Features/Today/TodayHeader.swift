import SwiftUI

/// Header estilo Avena: racha, navegación de fechas y acceso al perfil.
struct TodayHeader: View {
    let streak: Int
    @Binding var date: Date
    let onOpenGuide: () -> Void

    private let calendar = Calendar.chalk
    private var today: Date { calendar.startOfDay(for: .now) }
    private var isToday: Bool { date >= today }

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                streakPill
                Spacer(minLength: 0)
                dateSwitcher
                Spacer(minLength: 0)
                guideButton
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var streakPill: some View {
        Label {
            Text(streak, format: .number)
                .font(.title3.bold())
                .monospacedDigit()
                .contentTransition(.numericText())
        } icon: {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange.gradient)
        }
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 14)
        .frame(height: 52)
        .glassEffect(.regular.tint(.orange.opacity(0.18)), in: .capsule)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Racha de \(streak) días")
    }

    private var dateSwitcher: some View {
        HStack(spacing: 0) {
            arrowButton("Día anterior", systemImage: "chevron.left") { move(-1) }

            Button {
                withAnimation(.snappy) { date = today }
            } label: {
                VStack(spacing: 0) {
                    Text(title)
                        .font(.headline)
                    Text(date, format: .dateTime.day().month(.abbreviated).year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 104, minHeight: 44)
                .contentShape(.rect)
            }
            .accessibilityElement(children: .combine)
            .accessibilityHint("Regresa a hoy")

            arrowButton("Día siguiente", systemImage: "chevron.right") { move(1) }
                .disabled(isToday)
        }
        .font(.body.weight(.semibold))
        .buttonStyle(.plain)
        .padding(4)
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    /// Flecha con área táctil completa de 44 pt (el frame va dentro del label para que cuente al tocar).
    private func arrowButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 44, height: 44)
                .contentShape(.circle)
        }
        .accessibilityLabel(title)
    }

    private var guideButton: some View {
        Button(action: onOpenGuide) {
            Image(systemName: "gearshape")
                .font(.title3.weight(.semibold))
                .frame(width: 52, height: 52)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel("Guía")
    }

    private var title: String {
        let days = calendar.dateComponents([.day], from: date, to: today).day ?? 0
        return switch days {
        case 0: "Hoy"
        case 1: "Ayer"
        default: Weekday(date: date).displayName
        }
    }

    private func move(_ days: Int) {
        withAnimation(.snappy) {
            date = min(calendar.addingDays(days, to: date), today)
        }
    }
}
