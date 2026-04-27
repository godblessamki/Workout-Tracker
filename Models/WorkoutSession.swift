//
//  WorkoutSession.swift
//  WorkoutTracker
//
//  Represents one actual trip to the gym performed against a specific routine.
//  e.g. "Chest + Back session on April 19 2026".
//
//  Sessions are NEVER deleted — they are the raw data that powers
//  progressive overload statistics over time.
//

import Foundation
import SwiftData

@Model
final class WorkoutSession {

    // MARK: - Stored Properties

    /// Stable identifier.
    var id: UUID

    /// The date/time the session was started (set automatically on init).
    var date: Date

    // MARK: - Relationships

    /// Which routine was performed. Optional because SwiftData requires the
    /// inverse side of a to-many to be optional.
    var routine: WorkoutRoutine?

    /// One LoggedSet per exercise in the routine for this session.
    /// Cascade: if a session is somehow deleted, its sets go with it.
    @Relationship(deleteRule: .cascade, inverse: \LoggedSet.session)
    var loggedSets: [LoggedSet] = []

    // MARK: - Init

    init(date: Date = .now, routine: WorkoutRoutine) {
        self.id      = UUID()
        self.date    = date
        self.routine = routine
    }

    // MARK: - Helpers

    /// Formatted date string for display in the UI, e.g. "19 Apr 2026".
    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    /// Returns the LoggedSet for a given exercise within this session, if any.
    func loggedSet(for exercise: RoutineExercise) -> LoggedSet? {
        loggedSets.first { $0.exercise?.id == exercise.id }
    }
}
