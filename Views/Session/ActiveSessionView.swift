//
//  ActiveSessionView.swift
//  WorkoutTracker
//
//  The core workout logging interface. Displays one exercise at a time
//  with large typography and inputs, using a PageTabViewStyle for smooth
//  swiping between exercises.
//

import SwiftUI
import SwiftData

struct ActiveSessionView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg

    let session: WorkoutSession
    @State private var viewModel = ActiveSessionViewModel()

    // MARK: - Validation State
    @State private var showingEmptySessionAlert = false
    @State private var showingPartialEntryAlert = false
    @State private var showingSaveErrorAlert = false
    @State private var partialEntryMessage = ""

    // We can assume routine is non-nil for an active session
    private var exercises: [RoutineExercise] {
        session.routine?.sortedExercises ?? []
    }

    var body: some View {
        ZStack {
            // Dark background for a more immersive gym feel
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            if exercises.isEmpty {
                Text("No exercises in this routine.")
                    .font(.title)
                    .foregroundStyle(.secondary)
            } else {
                TabView(selection: $viewModel.currentIndex) {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        ExercisePage(
                            exercise: exercise,
                            session: session,
                            viewModel: viewModel,
                            isLast: index == exercises.count - 1,
                            onNext: {
                                withAnimation {
                                    if index < exercises.count - 1 {
                                        viewModel.currentIndex += 1
                                    } else {
                                        finishSession()
                                    }
                                }
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(session.routine?.name ?? "Workout")
                        .font(.headline)
                    Text(session.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Finish") {
                    finishSession()
                }
                .fontWeight(.bold)
            }
        }
        .onAppear {
            // Initialise inputs dictionary
            for exercise in exercises {
                viewModel.prepareInput(for: exercise)
            }
            
            // Start Live Activity
            if !exercises.isEmpty, let routineName = session.routine?.name {
                viewModel.startActivity(
                    routineName: routineName,
                    currentExerciseName: exercises[0].name,
                    currentExerciseIndex: 0,
                    totalExercises: exercises.count
                )
            }
        }
        .onChange(of: viewModel.currentIndex) { _, newValue in
            if newValue < exercises.count {
                viewModel.updateActivity(
                    currentExerciseName: exercises[newValue].name,
                    currentExerciseIndex: newValue,
                    totalExercises: exercises.count
                )
            }
        }
        .onDisappear {
            viewModel.endActivity()
        }
        // MARK: - Validation Alerts
        .alert("Incomplete Entry", isPresented: $showingPartialEntryAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(partialEntryMessage)
        }
        .alert("Empty Workout", isPresented: $showingEmptySessionAlert) {
            Button("Discard Session", role: .destructive) {
                viewModel.discardSession(session: session, context: modelContext)
                dismiss()
            }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("You haven't logged any sets yet. Do you want to discard this session?")
        }
        .alert("Save Failed", isPresented: $showingSaveErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to save your session. Please try again.")
        }
    }

    private func finishSession() {
        let result = viewModel.validateAndSave(session: session, context: modelContext, weightUnit: weightUnit)
        
        switch result {
        case .success:
            dismiss()
        case .emptySession:
            showingEmptySessionAlert = true
        case .partialEntry(let exerciseName):
            partialEntryMessage = "You entered partial data for \(exerciseName). Please enter both Weight and Reps, or clear both to skip it."
            showingPartialEntryAlert = true
        case .saveFailed:
            showingSaveErrorAlert = true
        }
    }
}

fileprivate struct ExercisePage: View {
    let exercise: RoutineExercise
    let session: WorkoutSession
    var viewModel: ActiveSessionViewModel
    let isLast: Bool
    let onNext: () -> Void

    @FocusState private var isFocused: Bool
    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .kg

    var body: some View {
        VStack(spacing: 40) {
            
            Spacer()
            
            // 1. Huge Exercise Name
            Text(exercise.name)
                .font(.system(size: 48, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .padding(.horizontal)

            // 2. Previous Best (if available)
            if let previous = viewModel.previousBest(for: exercise, currentSession: session) {
                VStack(spacing: 8) {
                    Text("PREVIOUS BEST")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .tracking(2)
                    
                    Text("\(weightUnit.formatted(previous.weightKg)) × \(previous.reps)")
                        .font(.title2.bold())
                        .foregroundStyle(.blue)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 8) {
                    Text("PREVIOUS BEST")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .tracking(2)
                    Text("First time!")
                        .font(.title2.bold())
                        .foregroundStyle(.secondary)
                }
                .padding()
            }

            // 3. Inputs for Current Sets
            ScrollView {
                VStack(spacing: 16) {
                    let count = viewModel.inputs[exercise.id]?.count ?? 1
                    ForEach(0..<count, id: \.self) { index in
                        HStack(spacing: 16) {
                            VStack {
                                if index == 0 {
                                    Text("WEIGHT")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                        .tracking(2)
                                }
                                
                                TextField("0", text: viewModel.weightBinding(for: exercise, index: index))
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .focused($isFocused)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            Text("×")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.tertiary)
                                .padding(.top, index == 0 ? 20 : 0)
                            
                            VStack {
                                if index == 0 {
                                    Text("REPS")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                        .tracking(2)
                                }
                                
                                TextField("0", text: viewModel.repsBinding(for: exercise, index: index))
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .minimumScaleFactor(0.3)
                                    .lineLimit(1)
                                    .multilineTextAlignment(.center)
                                    .focused($isFocused)
                                    .padding()
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            if count > 1 {
                                Button(action: {
                                    withAnimation {
                                        viewModel.removeSet(for: exercise, at: index)
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.title2)
                                }
                                .padding(.top, index == 0 ? 20 : 0)
                            }
                        }
                    }
                    
                    Button {
                        withAnimation {
                            viewModel.addSet(for: exercise)
                        }
                    } label: {
                        Text("+ Add Set")
                            .font(.headline)
                            .foregroundStyle(.blue)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // 4. Big Action Button
            Button {
                isFocused = false
                onNext()
            } label: {
                HStack {
                    Text(isLast ? "Finish Workout" : "Next Exercise")
                        .font(.title2.bold())
                    if !isLast {
                        Image(systemName: "chevron.right")
                            .font(.title2.bold())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(isLast ? Color.green : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: (isLast ? Color.green : Color.blue).opacity(0.3), radius: 10, y: 5)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60) // Extra padding for tab indicator
        }
        // Tap outside to dismiss keyboard
        .onTapGesture {
            isFocused = false
        }
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
    
    let e1 = RoutineExercise(name: "Bench Press", order: 0, routine: routine)
    let e2 = RoutineExercise(name: "Pull-ups", order: 1, routine: routine)
    container.mainContext.insert(e1)
    container.mainContext.insert(e2)
    
    let session = WorkoutSession(routine: routine)
    container.mainContext.insert(session)
    
    // Add a previous best
    let oldSession = WorkoutSession(date: Date().addingTimeInterval(-86400 * 2), routine: routine)
    container.mainContext.insert(oldSession)
    let bestSet = LoggedSet(reps: 8, weightKg: 100, exercise: e1, session: oldSession)
    container.mainContext.insert(bestSet)

    let view = NavigationStack {
        ActiveSessionView(session: session)
    }
    .modelContainer(container)
    
    return view
}
