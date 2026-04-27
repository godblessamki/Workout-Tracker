//
//  DashboardView.swift
//  WorkoutTracker
//
//  The app's home screen. Shows every saved WorkoutRoutine with:
//    • The number of exercises it contains
//    • The date of the last time it was performed
//    • A "Start Session" button that creates a session and navigates to it
//
//  Navigation to ActiveSessionView is driven by the `activeSession` state
//  variable. When it becomes non-nil, SwiftUI's .navigationDestination(item:)
//  pushes the active session screen automatically.
//

import SwiftUI
import SwiftData

struct DashboardView: View {

    // MARK: - Environment & Query

    @Environment(\.modelContext) private var modelContext

    /// All routines, sorted by creation date (oldest first).
    @Query(sort: \WorkoutRoutine.createdAt, order: .forward)
    private var routines: [WorkoutRoutine]

    // MARK: - ViewModel & State

    @State private var viewModel = SessionViewModel()

    /// When set, triggers navigation into ActiveSessionView.
    @State private var activeSession: WorkoutSession?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if routines.isEmpty {
                    emptyStateView
                } else {
                    routineList
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                // Quick link to manage routines without switching tabs
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: RoutineListView()) {
                        Label("Routines", systemImage: "list.bullet.clipboard")
                    }
                }
            }
            // Navigates to ActiveSessionView when a session is started.
            // Using item: binds the destination's lifetime to the session object.
            .navigationDestination(item: $activeSession) { session in
                ActiveSessionView(session: session)
            }
        }
    }

    // MARK: - Subviews

    /// Shown when the user hasn't created any routines yet.
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Routines Yet", systemImage: "dumbbell")
        } description: {
            Text("Go to the Routines tab to set up your first workout routine.")
        } actions: {
            // Deep-link shortcut inside the Dashboard itself
            NavigationLink(destination: RoutineListView()) {
                Label("Create a Routine", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    /// The scrollable list of routines with Start Session buttons.
    private var routineList: some View {
        List(routines) { routine in
            HStack(alignment: .center, spacing: 12) {

                // Left column: routine info
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(.headline)

                    // Exercise count
                    Text("\(routine.exercises.count) exercise\(routine.exercises.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Last session date (if any sessions have been completed)
                    if let lastSession = routine.sortedSessions.first {
                        Text("Last: \(lastSession.formattedDate)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                // Start Session button
                Button {
                    let session = viewModel.startSession(for: routine, context: modelContext)
                    activeSession = session
                } label: {
                    Label("Start", systemImage: "play.fill")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                // Can't start a session with no exercises
                .disabled(routine.exercises.isEmpty)
            }
            .padding(.vertical, 6)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: WorkoutRoutine.self, RoutineExercise.self, WorkoutSession.self, LoggedSet.self,
        configurations: config
    )

    // Seed some data for the preview
    let r1 = WorkoutRoutine(name: "Chest + Back")
    let r2 = WorkoutRoutine(name: "Legs")
    container.mainContext.insert(r1)
    container.mainContext.insert(r2)
    container.mainContext.insert(RoutineExercise(name: "Bench Press", order: 0, routine: r1))
    container.mainContext.insert(RoutineExercise(name: "Pull-up", order: 1, routine: r1))

    return DashboardView()
        .modelContainer(container)
}
