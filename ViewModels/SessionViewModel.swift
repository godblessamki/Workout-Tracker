//
//  SessionViewModel.swift
//  WorkoutTracker
//
//  Handles creating new WorkoutSessions. Kept separate from RoutineViewModel
//  because session lifecycle (start, finish) will grow in complexity in
//  Steps 4 & 5. Separation makes each ViewModel's responsibility clear.
//

import Foundation
import SwiftData

/// Manages the lifecycle of a WorkoutSession.
@Observable
final class SessionViewModel {

    // MARK: - Session Creation

    /// Creates a new WorkoutSession for the given routine, inserts it into
    /// SwiftData, and returns it so the caller can navigate to it.
    ///
    /// - Parameters:
    ///   - routine: The routine the user chose to perform today.
    ///   - context: The SwiftData ModelContext from the SwiftUI environment.
    /// - Returns: The newly created, persisted WorkoutSession.
    @discardableResult
    func startSession(for routine: WorkoutRoutine, context: ModelContext) -> WorkoutSession {
        let session = WorkoutSession(date: .now, routine: routine)
        context.insert(session)

        // Append to the routine's sessions array so the relationship is
        // immediately visible without waiting for SwiftData to sync.
        routine.sessions.append(session)

        return session
    }
}
