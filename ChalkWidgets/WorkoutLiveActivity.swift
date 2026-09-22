import ActivityKit
import SwiftUI
import WidgetKit

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            WorkoutLockScreenView(title: context.attributes.title, state: context.state)
                .activityBackgroundTint(LiveActivityPalette.background)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ExerciseActivityThumbnail(mediaPath: state.mediaPath, size: 48)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if state.isFinished {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title)
                            .foregroundStyle(LiveActivityPalette.lime)
                    } else {
                        CompleteExerciseButton(state: state, size: 48)
                            .padding(.trailing, 4)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(state.isFinished ? "¡Entrenamiento completo!" : state.name)
                            .font(.headline)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.8)
                        Text("\(min(state.completed + 1, state.total)) de \(state.total) · \(context.attributes.title)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if !state.isFinished {
                        VStack(spacing: 8) {
                            WorkoutStatsRow(state: state)
                            if let next = state.nextName {
                                Text("Sigue: \(next)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(LiveActivityPalette.lime)
                    Text(state.isFinished ? "Listo" : state.name)
                        .lineLimit(1)
                        .frame(maxWidth: 90, alignment: .leading)
                }
                .font(.caption.weight(.semibold))
            } compactTrailing: {
                Text(state.isFinished ? "✓" : "\(state.sets) series")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(state.isExtra ? LiveActivityPalette.lavender : LiveActivityPalette.lime)
            } minimal: {
                ZStack {
                    Circle()
                        .trim(from: 0, to: state.progress)
                        .stroke(LiveActivityPalette.lime, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(state.sets)")
                        .font(.caption2.bold())
                }
            }
            .keylineTint(LiveActivityPalette.lime)
        }
    }
}
