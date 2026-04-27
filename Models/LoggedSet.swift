//
//  LoggedSet.swift
//  WorkoutTracker
//
//  The atomic unit of workout data: one exercise's result for one session.
//  e.g. "Bench Press — 8 reps @ 100 kg on April 19 2026".
//
//  IMPORTANT: Weight is ALWAYS stored in kilograms, regardless of the
//  user's display preference. The UI layer is responsible for converting
//  to/from lbs using WeightUnit.convert(_:). This prevents data corruption
//  if the user switches units mid-use.
//

import Foundation
import SwiftData

@Model
final class LoggedSet {

    // MARK: - Stored Properties

    /// Stable identifier.
    var id: UUID

    /// Number of repetitions performed.
    var reps: Int

    /// Weight lifted, **always stored in kg**.
    var weightKg: Double

    // MARK: - Relationships

    /// Which exercise this set is for.
    var exercise: RoutineExercise?

    /// Which session this set belongs to.
    var session: WorkoutSession?

    // MARK: - Init

    /// - Parameters:
    ///   - reps:      Reps performed.
    ///   - weightKg:  Weight in **kg** (convert before calling if user is in lbs mode).
    ///   - exercise:  The `RoutineExercise` being logged.
    ///   - session:   The active `WorkoutSession`.
    init(reps: Int, weightKg: Double, exercise: RoutineExercise, session: WorkoutSession) {
        self.id        = UUID()
        self.reps      = reps
        self.weightKg  = weightKg
        self.exercise  = exercise
        self.session   = session
    }

    // MARK: - Helpers

    /// Volume — useful for future progressive-overload statistics.
    var volume: Double { Double(reps) * weightKg }
}

// MARK: - Weight Unit Helper

/// Encapsulates unit conversion so no magic numbers appear in views.
enum WeightUnit: String {
    case kg  = "kg"
    case lbs = "lbs"

    static let lbsPerKg: Double = 2.20462

    /// Converts a kg value to the appropriate display unit.
    func display(_ kg: Double) -> Double {
        switch self {
        case .kg:  return kg
        case .lbs: return kg * WeightUnit.lbsPerKg
        }
    }

    /// Converts a user-entered value back to kg for storage.
    func toKg(_ value: Double) -> Double {
        switch self {
        case .kg:  return value
        case .lbs: return value / WeightUnit.lbsPerKg
        }
    }

    /// Formatted weight string, e.g. "100 kg" or "220.5 lbs".
    func formatted(_ kg: Double) -> String {
        let value = display(kg)
        // Show one decimal place only when needed
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
        return "\(formatted) \(rawValue)"
    }
}
