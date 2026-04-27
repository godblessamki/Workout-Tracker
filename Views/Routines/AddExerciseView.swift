//
//  AddExerciseView.swift
//  WorkoutTracker
//
//  A focused sheet for naming and saving a new exercise to a routine.
//
//  Kept intentionally simple: one text field, Save/Cancel toolbar buttons,
//  and auto-focus via @FocusState so the keyboard appears immediately
//  when the sheet opens — minimising taps for the user.
//

import SwiftUI
import SwiftData

struct AddExerciseView: View {

    // MARK: - Environment & Input

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// The routine to which the new exercise will be added.
    let routine: WorkoutRoutine

    // MARK: - ViewModel & State

    @State private var viewModel = RoutineViewModel()
    @State private var exerciseName = ""

    /// @FocusState automatically brings up the keyboard when the sheet appears.
    @FocusState private var isNameFieldFocused: Bool

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Name") {
                    TextField("e.g. Bench Press", text: $exerciseName)
                        .focused($isNameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit(save)   // hitting Return on the keyboard triggers save
                }

                Section {
                    Text("This exercise will be added to **\(routine.name)**.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: save)
                        .disabled(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            // Auto-focus the field as soon as the sheet appears
            .onAppear { isNameFieldFocused = true }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func save() {
        guard !exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        viewModel.addExercise(name: exerciseName, to: routine, context: modelContext)
        dismiss()
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

    return AddExerciseView(routine: routine)
        .modelContainer(container)
}
