import SwiftUI

struct FreeDayCard: View {
    let hasMakeups: Bool
    let onMakeup: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if !hasMakeups {
                Image(systemName: "leaf.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color(.lime).gradient)
                Text("Día libre")
                    .font(.title2.bold())
                Text("Tu racha sigue intacta. Si faltaste algún día esta semana, puedes reponerlo hoy.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button(hasMakeups ? "Reponer otro día" : "Reponer un día", systemImage: "arrow.triangle.2.circlepath", action: onMakeup)
                .buttonStyle(.glassProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .card()
    }
}
