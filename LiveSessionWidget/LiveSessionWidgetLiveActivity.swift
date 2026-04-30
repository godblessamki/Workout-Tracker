import ActivityKit
import WidgetKit
import SwiftUI

struct LiveSessionWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveSessionAttributes.self) { context in
            // Lock screen/banner UI goes here
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.routineName)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(context.state.currentExerciseName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(context.state.currentExerciseIndex + 1)")
                        .font(.title.bold())
                        .foregroundStyle(.blue)
                    Text("/\(context.state.totalExercises)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            // Setting backgrounds for dark/light mode compatibility
            .activityBackgroundTint(Color(UIColor.systemBackground))
            .activitySystemActionForegroundColor(Color.blue)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.
                DynamicIslandExpandedRegion(.leading) {
                    Text("Workout")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.currentExerciseIndex + 1)/\(context.state.totalExercises)")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.currentExerciseName)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                }
            } compactLeading: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text("\(context.state.currentExerciseIndex + 1)/\(context.state.totalExercises)")
                    .foregroundColor(.blue)
            } minimal: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(.blue)
            }
            .widgetURL(URL(string: "workouttracker://session"))
            .keylineTint(Color.blue)
        }
    }
}

extension LiveSessionAttributes {
    fileprivate static var preview: LiveSessionAttributes {
        LiveSessionAttributes(routineName: "Chest + Back")
    }
}

extension LiveSessionAttributes.ContentState {
    fileprivate static var step1: LiveSessionAttributes.ContentState {
        LiveSessionAttributes.ContentState(currentExerciseName: "Bench Press", currentExerciseIndex: 0, totalExercises: 5)
    }
}

#Preview("Notification", as: .content, using: LiveSessionAttributes.preview) {
   LiveSessionWidgetLiveActivity()
} contentStates: {
    LiveSessionAttributes.ContentState.step1
}
