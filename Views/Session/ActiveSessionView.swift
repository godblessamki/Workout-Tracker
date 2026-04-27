//
//  ActiveSessionView.swift
//  WorkoutTracker
//
//  ⚠️  PLACEHOLDER — will be fully implemented in Step 4.
//
//  This stub exists so DashboardView's .navigationDestination(item:) compiles
//  without error. It accepts a WorkoutSession and displays the routine name
//  and start date until the real exercise-logging UI is built.
//

import SwiftUI
import SwiftData

struct ActiveSessionView: View {

    // The session that was just created by DashboardView.
    let session: WorkoutSession

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text(session.routine?.name ?? "Workout")
                .font(.largeTitle.bold())

            Text(session.formattedDate)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Exercise logging coming in Step 4! 💪")
                .font(.body)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .navigationTitle("Active Session")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: WorkoutRoutine.self, RoutineExercise.self, WorkoutSession.self, LoggedSet.self,
        configurations: config
    )
    let routine = WorkoutRoutine(name: "Chest + Back")
    container.mainContext.insert(routine)
    let session = WorkoutSession(routine: routine)
    container.mainContext.insert(session)

    return NavigationStack {
        ActiveSessionView(session: session)
    }
    .modelContainer(container)
}
