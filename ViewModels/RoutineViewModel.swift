//
//  RoutineViewModel.swift
//  WorkoutTracker
//
//  The ViewModel for routine and exercise management.
//
//  This class is intentionally slim: SwiftData models are themselves
//  @Observable, so the ViewModel's job is purely to encapsulate mutation
//  logic (insert/delete) rather than holding displayable state.
//
//  Usage: instantiate with @State in a View, then call methods passing
//  the modelContext obtained from @Environment(\.modelContext).
//

import Foundation
import SwiftData

/// Manages create/delete operations for WorkoutRoutine and RoutineExercise.
@Observable
final class RoutineViewModel {

    // MARK: - Routine Operations

    /// Creates a new WorkoutRoutine and inserts it into the SwiftData context.
    /// - Parameters:
    ///   - name:    The user-entered routine name. Trimmed before saving.
    ///   - context: The SwiftData ModelContext from the SwiftUI environment.
    func addRoutine(name: String, context: ModelContext) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let routine = WorkoutRoutine(name: trimmed)
        context.insert(routine)
    }

    /// Deletes a WorkoutRoutine. Cascade rules on the model handle child
    /// records (exercises, sessions, logged sets) automatically.
    func deleteRoutine(_ routine: WorkoutRoutine, context: ModelContext) {
        context.delete(routine)
    }

    // MARK: - Exercise Operations

    /// Appends a new RoutineExercise to the given routine.
    /// The exercise's `order` is set to the current exercise count so it
    /// always appears at the bottom of the list.
    func addExercise(name: String, to routine: WorkoutRoutine, context: ModelContext) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newOrder = routine.exercises.count
        let exercise = RoutineExercise(name: trimmed, order: newOrder, routine: routine)
        context.insert(exercise)
    }

    /// Removes a RoutineExercise and re-normalises the `order` values of
    /// the remaining exercises so the list stays contiguous (0, 1, 2 …).
    func deleteExercise(_ exercise: RoutineExercise, from routine: WorkoutRoutine, context: ModelContext) {
        routine.exercises.removeAll { $0.id == exercise.id }
        context.delete(exercise)

        // Re-number after deletion to keep order values tidy
        for (index, ex) in routine.sortedExercises.enumerated() {
            ex.order = index
        }
    }
}
