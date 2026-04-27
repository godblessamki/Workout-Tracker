//
//  RoutineDetailView.swift
//  WorkoutTracker
//
//  Displays the exercises within a single WorkoutRoutine and lets the user
//  add new exercises or delete existing ones.
//
//  Because WorkoutRoutine is a SwiftData @Model class, it conforms to
//  Observable automatically. SwiftUI tracks property accesses at runtime, so
//  any change to `routine.exercises` will cause this view to re-render
//  without needing @State or @Binding.
//

import SwiftUI
import SwiftData

struct RoutineDetailView: View {

    // MARK: - Environment & Input

    @Environment(\.modelContext) private var modelContext

    /// The routine being edited. Passed in from RoutineListView.
    /// SwiftData's @Model is Observable, so changes propagate automatically.
    let routine: WorkoutRoutine

    // MARK: - ViewModel & State

    @State private var viewModel = RoutineViewModel()

    /// Controls the "Add Exercise" sheet.
    @State private var showingAddExercise = false

    // MARK: - Body

    var body: some View {
        Group {
            if routine.sortedExercises.isEmpty {
                emptyStateView
            } else {
                exerciseList
            }
        }
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddExercise = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(routine: routine)
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Exercises Yet",
            systemImage: "figure.strengthtraining.traditional",
            description: Text("Tap + to add exercises to \(routine.name).")
        )
    }

    private var exerciseList: some View {
        List {
            ForEach(routine.sortedExercises) { exercise in
                HStack {
                    // Order badge — visual cue for the exercise's position
                    Text("\(exercise.order + 1)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 24, alignment: .center)

                    Text(exercise.name)
                        .font(.body)
                }
                .padding(.vertical, 2)
            }
            .onDelete { indexSet in
                let sorted = routine.sortedExercises
                for index in indexSet {
                    viewModel.deleteExercise(sorted[index], from: routine, context: modelContext)
                }
            }
        }
    }
}

#Preview {
    // Build a quick in-memory routine for the canvas
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: WorkoutRoutine.self, RoutineExercise.self, WorkoutSession.self, LoggedSet.self,
        configurations: config
    )
    let routine = WorkoutRoutine(name: "Chest + Back")
    container.mainContext.insert(routine)
    let e1 = RoutineExercise(name: "Bench Press", order: 0, routine: routine)
    let e2 = RoutineExercise(name: "Pull-up", order: 1, routine: routine)
    container.mainContext.insert(e1)
    container.mainContext.insert(e2)

    return NavigationStack {
        RoutineDetailView(routine: routine)
    }
    .modelContainer(container)
}
