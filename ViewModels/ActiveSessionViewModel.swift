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
    var inputs: [UUID: (reps: String, weight: String)] = [:]
    
    // The currently displayed exercise index.
    var currentIndex: Int = 0
    
    init() {}
    
    /// Returns the highest weight LoggedSet from the most recent session
    /// that is NOT the current session.
    func previousBest(for exercise: RoutineExercise, currentSession: WorkoutSession) -> LoggedSet? {
        // Find the most recent set performed for this exercise, excluding this session
        return exercise.previousLoggedSet(excludingSession: currentSession)
    }
    
    /// Prepares the input state for a given exercise, defaulting to empty strings if not yet set.
    func prepareInput(for exercise: RoutineExercise) {
        if inputs[exercise.id] == nil {
            inputs[exercise.id] = (reps: "", weight: "")
        }
    }
    
    // Helper to safely bind to the dictionary
    func binding(for exercise: RoutineExercise, keyPath: WritableKeyPath<(reps: String, weight: String), String>) -> Binding<String> {
        Binding<String>(
            get: {
                self.inputs[exercise.id]?[keyPath: keyPath] ?? ""
            },
            set: { newValue in
                if self.inputs[exercise.id] == nil {
                    self.inputs[exercise.id] = (reps: "", weight: "")
                }
                self.inputs[exercise.id]?[keyPath: keyPath] = newValue
            }
        )
    }
    
    func repsBinding(for exercise: RoutineExercise) -> Binding<String> {
        binding(for: exercise, keyPath: \.reps)
    }
    
    func weightBinding(for exercise: RoutineExercise) -> Binding<String> {
        binding(for: exercise, keyPath: \.weight)
    }
}
