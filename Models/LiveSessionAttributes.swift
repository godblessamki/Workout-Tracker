import Foundation
import ActivityKit

public struct LiveSessionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about the current workout
        public var currentExerciseName: String
        public var currentExerciseIndex: Int
        public var totalExercises: Int
    }

    // Fixed non-changing properties about the workout
    public var routineName: String
}
