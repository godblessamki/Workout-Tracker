//
//  ContentView.swift
//  WorkoutTracker
//
//  Root container for the app. Uses a TabView with two tabs:
//    • Dashboard — where sessions are started (built in Step 3)
//    • Routines  — where routines and exercises are managed (built in Step 2)
//
//  The tab order puts Dashboard first because it is the most frequent
//  destination once routines are set up.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {

            // MARK: Dashboard (Step 3 — fully functional)
            Tab("Dashboard", systemImage: "house.fill") {
                DashboardView()
            }

            // MARK: Routines (Step 2 — fully functional)
            Tab("Routines", systemImage: "list.bullet.clipboard") {
                RoutineListView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutRoutine.self, RoutineExercise.self,
                               WorkoutSession.self, LoggedSet.self],
                        inMemory: true)
}
