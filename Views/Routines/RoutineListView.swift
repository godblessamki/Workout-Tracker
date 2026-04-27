//
//  RoutineListView.swift
//  WorkoutTracker
//
//  The top-level screen for managing workout routines.
//
//  @Query automatically keeps the list in sync with SwiftData — any insert
//  or delete made via modelContext is reflected here instantly without
//  manually refreshing.
//

import SwiftUI
import SwiftData

struct RoutineListView: View {

    // MARK: - Environment & Query

    /// The shared SwiftData context, used to pass into ViewModel methods.
    @Environment(\.modelContext) private var modelContext

    /// SwiftData query — automatically re-renders the list on any change.
    /// Sorted by creation date so newest routines appear at the bottom.
    @Query(sort: \WorkoutRoutine.createdAt, order: .forward)
    private var routines: [WorkoutRoutine]

    // MARK: - ViewModel & State

    /// @State because RoutineViewModel is @Observable (not ObservableObject).
    @State private var viewModel = RoutineViewModel()

    /// Controls visibility of the "Add Routine" sheet.
    @State private var showingAddRoutine = false

    /// Text binding for the new routine name text field.
    @State private var newRoutineName = ""

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
            .navigationTitle("My Routines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddRoutine = true
                    } label: {
                        Label("Add Routine", systemImage: "plus")
                    }
                }
            }
            // Sheet for creating a new routine
            .sheet(isPresented: $showingAddRoutine) {
                addRoutineSheet
            }
        }
    }

    // MARK: - Subviews

    /// Placeholder shown when no routines have been created yet.
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Routines Yet",
            systemImage: "dumbbell",
            description: Text("Tap + to create your first workout routine.")
        )
    }

    /// The scrollable list of existing routines.
    private var routineList: some View {
        List {
            ForEach(routines) { routine in
                NavigationLink(destination: RoutineDetailView(routine: routine)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.name)
                            .font(.headline)
                        Text("\(routine.exercises.count) exercise\(routine.exercises.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete { indexSet in
                // Delete whichever rows the user swiped
                for index in indexSet {
                    viewModel.deleteRoutine(routines[index], context: modelContext)
                }
            }
        }
    }

    /// The sheet content for adding a new routine.
    private var addRoutineSheet: some View {
        NavigationStack {
            Form {
                Section("Routine Name") {
                    TextField("e.g. Chest + Back", text: $newRoutineName)
                        // Dismiss keyboard on return
                        .submitLabel(.done)
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newRoutineName = ""
                        showingAddRoutine = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addRoutine(name: newRoutineName, context: modelContext)
                        newRoutineName = ""
                        showingAddRoutine = false
                    }
                    // Disabled until the user has typed something
                    .disabled(newRoutineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        // Compact height — only a single text field
        .presentationDetents([.medium])
    }
}

#Preview {
    RoutineListView()
        .modelContainer(for: [WorkoutRoutine.self, RoutineExercise.self,
                               WorkoutSession.self, LoggedSet.self],
                        inMemory: true)
}
