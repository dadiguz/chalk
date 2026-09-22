import SwiftUI

struct MissedDayBanner: View {
    let blocks: [RoutineBlock]

    var body: some View {
        Label {
            Text("Ayer no hiciste \(blocks.map(\.title).formatted(.list(type: .and))). Puedes reponerlo en un día libre.")
                .font(.subheadline)
        } icon: {
            Image(systemName: "calendar.badge.exclamationmark")
                .foregroundStyle(.orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.orange.opacity(0.12), in: .rect(cornerRadius: 18))
    }
}
