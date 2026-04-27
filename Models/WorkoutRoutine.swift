//
//  WorkoutRoutine.swift
//  WorkoutTracker
//
//  Represents the *blueprint* for a workout, e.g. "Chest + Back".
//  A routine owns a list of exercises and accumulates sessions over time.
//  Both relationships use .cascade so that deleting a routine cleans up
//  all child records — exercises and every logged session.
//

import Foundation
import SwiftData

@Model
final class WorkoutRoutine {

    // MARK: - Stored Properties

    /// Stable identifier used for equality checks and dictionary keys.
    var id: UUID

    /// Human-readable name the user gave this routine, e.g. "Legs".
    var name: String

    /// When the routine was first created (useful for future sorting).
    var createdAt: Date

    // MARK: - Relationships

    /// The exercises that belong to this routine, ordered by `order`.
    /// Cascade: deleting this routine removes all its exercises.
    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.routine)
    var exercises: [RoutineExercise] = []

    /// Every workout session that was performed using this routine.
    /// We keep all sessions forever — they power the progressive overload history.
    /// Cascade: deleting the routine still removes its orphaned sessions.
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.routine)
    var sessions: [WorkoutSession] = []

    // MARK: - Init

    init(name: String) {
        self.id       = UUID()
        self.name     = name
        self.createdAt = .now
    }

    // MARK: - Helpers

    /// Returns exercises sorted by their display order.
    var sortedExercises: [RoutineExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    /// Returns sessions sorted newest-first.
    var sortedSessions: [WorkoutSession] {
        sessions.sorted { $0.date > $1.date }
    }
}
