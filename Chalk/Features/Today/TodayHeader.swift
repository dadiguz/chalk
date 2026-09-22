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
        HStack(spacing: 4) {
            Button("Día anterior", systemImage: "chevron.left") { move(-1) }
                .labelStyle(.iconOnly)
                .frame(width: 40, height: 40)

            VStack(spacing: 0) {
                Text(title)
                    .font(.headline)
                Text(date, format: .dateTime.day().month(.abbreviated).year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 104)
            .onTapGesture { withAnimation(.snappy) { date = today } }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Regresa a hoy")

            Button("Día siguiente", systemImage: "chevron.right") { move(1) }
                .labelStyle(.iconOnly)
                .frame(width: 40, height: 40)
                .disabled(isToday)
        }
        .font(.body.weight(.semibold))
        .buttonStyle(.plain)
        .padding(6)
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    private var guideButton: some View {
        Button("Guía", systemImage: "gearshape", action: onOpenGuide)
            .labelStyle(.iconOnly)
            .font(.title3.weight(.semibold))
            .frame(width: 52, height: 52)
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
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
