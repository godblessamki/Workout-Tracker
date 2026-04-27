//
//  RoutineExercise.swift
//  WorkoutTracker
//
//  Represents a single exercise *within* a routine, e.g. "Bench Press".
//  It is owned by exactly one WorkoutRoutine and collects every LoggedSet
//  that has ever been performed for it across all sessions — this is what
//  drives the progressive overload history screen in a future step.
//

import Foundation
import SwiftData

@Model
final class RoutineExercise {

    // MARK: - Stored Properties

    /// Stable identifier.
    var id: UUID

    /// Display name of the exercise, e.g. "Incline Dumbbell Press".
    var name: String

    /// Zero-based position within the parent routine's exercise list.
    /// Lets us sort exercises predictably without relying on insertion order.
    var order: Int

    // MARK: - Relationships

    /// The routine this exercise belongs to.
    /// Declared as optional because SwiftData requires the inverse side
    /// of a to-many relationship to be optional.
    var routine: WorkoutRoutine?

    /// All sets ever logged for this exercise across every session.
    /// Cascade: deleting this exercise removes every historical log entry.
    /// NOTE: We never delete exercises in normal usage — only if the user
    ///       explicitly removes it from their routine — so history is preserved.
    @Relationship(deleteRule: .cascade, inverse: \LoggedSet.exercise)
    var loggedSets: [LoggedSet] = []

    // MARK: - Init

    init(name: String, order: Int, routine: WorkoutRoutine) {
        self.id      = UUID()
        self.name    = name
        self.order   = order
        self.routine = routine
    }

    // MARK: - Helpers

    /// Finds the LoggedSet from the most recent *completed* session
    /// (excluding the currently active one if provided).
    /// Returns nil if this exercise has never been logged before.
    func previousLoggedSet(excludingSession current: WorkoutSession? = nil) -> LoggedSet? {
        // Gather all sessions for this exercise that have been logged
        let sessions = loggedSets
            .compactMap { $0.session }
            .filter { $0.id != current?.id }   // exclude the in-progress session
            .sorted { $0.date > $1.date }       // newest first

        guard let lastSession = sessions.first else { return nil }

        // Return the single LoggedSet that belongs to the most recent session
        return loggedSets.first { $0.session?.id == lastSession.id }
    }
}
