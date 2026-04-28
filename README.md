# WorkoutTracker

A native iOS application designed to track gym workouts accurately and efficiently. WorkoutTracker allows users to define reusable workout routines, add specific exercises, and log sessions with a focus on progressive overload by surfacing performance data from previous sessions.

## 🚀 Features

- **Routine Management:** Create and customize workout blueprints (e.g., "Push", "Pull", "Legs").
- **Exercise Library:** Add specific exercises to each routine with defined ordering.
- **Active Session Logging:** Log reps and weight for each exercise during a workout.
- **Progressive Overload Tracking:** Automatically displays your best performance (weight and reps) from the most recent session for each exercise.
- **Persistent Storage:** All data is stored locally using **SwiftData**, ensuring your history is always available offline.
- **Unit Support:** Supports both **kg** and **lbs** (automatically handles conversions for storage).

## 🛠 Tech Stack

- **Language:** Swift 5.10+
- **UI Framework:** SwiftUI
- **Database:** SwiftData
- **Architecture:** MVVM (Model-View-ViewModel)

## 📁 Project Structure

```text
WorkoutTracker/
├── WorkoutTrackerApp.swift      # App entry point & ModelContainer setup
├── Models/                      # SwiftData @Model classes
│   ├── WorkoutRoutine.swift     # Routine blueprint
│   ├── RoutineExercise.swift    # Exercise within a routine
│   ├── WorkoutSession.swift     # A single workout session
│   └── LoggedSet.swift          # Data for a specific exercise set
├── ViewModels/                  # Business logic & state management
└── Views/                       # SwiftUI Views
    ├── Dashboard/               # Main entry screen
    ├── Routines/                # Routine creation & editing
    └── Session/                 # Active workout logging
```

## 📋 Data Retention & Privacy

WorkoutTracker is built with data integrity in mind:
- **Local Only:** Your data never leaves your device.
- **Full History:** Completed sessions are never deleted, providing a rich dataset for future progressive overload statistics.
- **Cascading Deletes:** Deleting a routine will clean up associated exercises and sessions to prevent data orphaning.

## 📝 Roadmap

1. [x] Step 1: SwiftData Schema Setup
2. [x] Step 2: Routine Creator View
3. [x] Step 3: Main Dashboard
4. [x] Step 4: Active Session View (Core Feature) - *Implemented immersive single-exercise focus with swipe flow*
5. [ ] Step 5: Session Persistence & Validation

---

*This project is built with stewardship and precision to help you reach your fitness goals.*
