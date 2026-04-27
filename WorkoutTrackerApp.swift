//
//  WorkoutTrackerApp.swift
//  WorkoutTracker
//
//  App entry point. Sets up the SwiftData ModelContainer with all four
//  models so every view in the hierarchy can access the shared store
//  via @Environment(\.modelContext).
//

import SwiftUI
import SwiftData

@main
struct WorkoutTrackerApp: App {

    // SwiftData's equivalent of a Core Data persistent store coordinator.
    // Passing all four @Model types ensures SwiftData creates the schema
    // and SQLite tables automatically on first launch.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutRoutine.self,
            RoutineExercise.self,
            WorkoutSession.self,
            LoggedSet.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Fatal: if the container can't be created the app cannot function.
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Inject the container into the SwiftUI environment.
        // Views use @Environment(\.modelContext) or @Query to access data.
        .modelContainer(sharedModelContainer)
    }
}
