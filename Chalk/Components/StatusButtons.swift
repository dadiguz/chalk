import SwiftUI

/// Par de botones ✕ / ✓. Tocar el botón activo regresa a pendiente.
struct StatusButtons: View {
    let status: EntryStatus?
    var accent: Color = Color(.lime)
    var onAccent: Color = Color(.onLime)
    let onChange: (EntryStatus?) -> Void

    var body: some View {
        HStack(spacing: 8) {
            button(for: .skipped, systemImage: "xmark", label: "Marcar como no hecho", fill: .secondary, iconOn: Color(.systemBackground))
            button(for: .done, systemImage: "checkmark", label: "Marcar como hecho", fill: accent, iconOn: onAccent)
        }
        .sensoryFeedback(.selection, trigger: status)
    }

    private func button(for target: EntryStatus, systemImage: String, label: String, fill: some ShapeStyle, iconOn: Color) -> some View {
        let isOn = status == target
        return Button(label, systemImage: systemImage) {
            onChange(isOn ? nil : target)
        }
        .labelStyle(.iconOnly)
        .font(.body.bold())
        .frame(width: 40, height: 40)
        .foregroundStyle(isOn ? AnyShapeStyle(iconOn) : AnyShapeStyle(.primary))
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(isOn ? AnyShapeStyle(fill) : AnyShapeStyle(.clear))
                .stroke(isOn ? AnyShapeStyle(.clear) : AnyShapeStyle(.tertiary), lineWidth: 1)
        }
        .contentShape(.rect(cornerRadius: 12))
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
