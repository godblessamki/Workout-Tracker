//
//  ActiveSessionViewModel.swift
//  WorkoutTracker
//
//  Manages the state for an active workout session.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
final class ActiveSessionViewModel {

    // Dictionary to hold user input for each exercise. Key is RoutineExercise.id.
    var inputs: [UUID: [(reps: String, weight: String)]] = [:]
    
    // The currently displayed exercise index.
    var currentIndex: Int = 0
    
    init() {}
    
    // Cache for previous best sets to avoid recomputing on every view render
    private var cachedPreviousBests: [UUID: LoggedSet?] = [:]
    
    /// Returns the highest weight LoggedSet from the most recent session
    /// that is NOT the current session.
    func previousBest(for exercise: RoutineExercise, currentSession: WorkoutSession) -> LoggedSet? {
        if let cached = cachedPreviousBests[exercise.id] {
            return cached
        }
        // Find the most recent set performed for this exercise, excluding this session
        let best = exercise.previousLoggedSet(excludingSession: currentSession)
        cachedPreviousBests[exercise.id] = best
        return best
    }
    
    /// Prepares the input state for a given exercise, defaulting to one empty set if not yet set.
    func prepareInput(for exercise: RoutineExercise) {
        if inputs[exercise.id] == nil || inputs[exercise.id]!.isEmpty {
            inputs[exercise.id] = [(reps: "", weight: "")]
        }
    }
    
    func addSet(for exercise: RoutineExercise) {
        inputs[exercise.id]?.append((reps: "", weight: ""))
    }
    
    func removeSet(for exercise: RoutineExercise, at index: Int) {
        if let count = inputs[exercise.id]?.count, count > 1 {
            inputs[exercise.id]?.remove(at: index)
        }
    }
    
    // Helper to safely bind to the dictionary array
    func binding(for exercise: RoutineExercise, index: Int, keyPath: WritableKeyPath<(reps: String, weight: String), String>) -> Binding<String> {
        Binding<String>(
            get: {
                guard let sets = self.inputs[exercise.id], index < sets.count else { return "" }
                return sets[index][keyPath: keyPath]
            },
            set: { newValue in
                if self.inputs[exercise.id] == nil {
                    self.inputs[exercise.id] = [(reps: "", weight: "")]
                }
                guard let count = self.inputs[exercise.id]?.count, index < count else { return }
                self.inputs[exercise.id]?[index][keyPath: keyPath] = newValue
            }
        )
    }
    
    func repsBinding(for exercise: RoutineExercise, index: Int) -> Binding<String> {
        binding(for: exercise, index: index, keyPath: \.reps)
    }
    
    func weightBinding(for exercise: RoutineExercise, index: Int) -> Binding<String> {
        binding(for: exercise, index: index, keyPath: \.weight)
    }
    
    enum SaveResult {
        case success
        case emptySession
        case partialEntry(exerciseName: String)
        case saveFailed
    }
    
    /// Validates the user's inputs and attempts to save the session.
    func validateAndSave(session: WorkoutSession, context: ModelContext, weightUnit: WeightUnit) -> SaveResult {
        var loggedAnySets = false
        var setsToSave: [LoggedSet] = []

        guard let routine = session.routine else { return .emptySession }

        // Process exercises in their ordered sequence for predictable error reporting
        for exercise in routine.sortedExercises {
            guard let exerciseSets = inputs[exercise.id] else { continue }
            
            for input in exerciseSets {
                let repsStr = input.reps.trimmingCharacters(in: .whitespacesAndNewlines)
                let weightStr = input.weight.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let isRepsEmpty = repsStr.isEmpty
                let isWeightEmpty = weightStr.isEmpty
                
                if isRepsEmpty && isWeightEmpty {
                    // User completely skipped this set; that's fine.
                    continue
                } else if isRepsEmpty || isWeightEmpty {
                    // They entered one but not the other.
                    return .partialEntry(exerciseName: exercise.name)
                } else if let reps = Int(repsStr), let weight = Double(weightStr), reps > 0, weight > 0 {
                    // Both are valid positive numbers; prepare the LoggedSet.
                    let weightKg = weightUnit.toKg(weight)
                    let set = LoggedSet(reps: reps, weightKg: weightKg, exercise: exercise, session: session)
                    setsToSave.append(set)
                    loggedAnySets = true
                } else {
                    // Text couldn't be parsed as a positive number (e.g. typed garbage or negative values).
                    return .partialEntry(exerciseName: exercise.name)
                }
            }
        }
        
        if !loggedAnySets {
            return .emptySession
        }
        
        // Everything is valid! Insert the new sets into SwiftData.
        for set in setsToSave {
            context.insert(set)
        }
        
        // Explicitly trigger a save to ensure data is written immediately.
        do {
            try context.save()
            return .success
        } catch {
            print("Failed to save session to SwiftData: \(error)")
            return .saveFailed
        }
    }
    
    /// Deletes the current session if the user chooses to discard it.
    func discardSession(session: WorkoutSession, context: ModelContext) {
        session.routine?.sessions.removeAll { $0.id == session.id }
        context.delete(session)
        // SwiftData will automatically save this deletion.
    }
}
