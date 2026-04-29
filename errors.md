# WorkoutTracker — Code Review

## Summary

The codebase is generally well-structured and well-documented. The MVVM separation is clean, SwiftData relationships are correctly defined, and the UI code is idiomatic SwiftUI. That said, I found **3 bugs**, **4 significant design problems**, and a handful of minor issues worth addressing.

---

## 🔴 Bugs

### 1. `previousLoggedSet()` returns an arbitrary set, not the best one

**File:** [RoutineExercise.swift](file:///Users/samuelkouril/Desktop/WorkoutTracker1/Models/RoutineExercise.swift#L57-L68)

```swift
func previousLoggedSet(excludingSession current: WorkoutSession? = nil) -> LoggedSet? {
    let sessions = loggedSets
        .compactMap { $0.session }
        .filter { $0.id != current?.id }
        .sorted { $0.date > $1.date }

    guard let lastSession = sessions.first else { return nil }

    // BUG: returns the FIRST matching set, not the BEST one
    return loggedSets.first { $0.session?.id == lastSession.id }
}
```

> [!CAUTION]
> The `ActiveSessionView` labels this "PREVIOUS BEST", but the code returns whichever `LoggedSet` happens to be first in the array — **not** the one with the highest weight or volume. If the user logs multiple sets per exercise in a future update, this will return a random set. Even with one set per exercise today, the name is misleading and the code is fragile.

**Fix:** Filter to the last session's sets, then sort by `weightKg` descending (or `volume`) and return `.first`.

---

### 2. Only one set per exercise is supported — silently drops data

**File:** [ActiveSessionViewModel.swift](file:///Users/samuelkouril/Desktop/WorkoutTracker1/ViewModels/ActiveSessionViewModel.swift#L16)

```swift
var inputs: [UUID: (reps: String, weight: String)] = [:]
```

The GEMINI.md plan explicitly calls for "multiple `LoggedSet` rows dynamically" per exercise, but the data structure is a flat dictionary keyed by `RoutineExercise.id` holding a **single** `(reps, weight)` tuple. There is no way for a user to log more than one set per exercise per session.

> [!IMPORTANT]
> This is a fundamental design gap. The model layer (`LoggedSet`) fully supports multiple sets per exercise per session, but the ViewModel and View hard-code a single set. This means all the "previous best" logic in `RoutineExercise` and the `volume` helper on `LoggedSet` are under-utilized.

**Fix:** Change the dictionary value to `[(reps: String, weight: String)]` (an array of tuples) and update `ExercisePage` to render a dynamic list of set rows with an "Add Set" button.

---

### 3. `validateAndSave` returns `.success` even when `context.save()` fails

**File:** [ActiveSessionViewModel.swift](file:///Users/samuelkouril/Desktop/WorkoutTracker1/ViewModels/ActiveSessionViewModel.swift#L110-L118)

```swift
do {
    try context.save()
    return .success
} catch {
    print("Failed to save session to SwiftData: \(error)")
    // Returns .success even on failure!
    return .success
}
```

> [!WARNING]
> If SwiftData fails to persist (e.g. disk full, schema migration error), the user sees a successful dismiss, their data is silently lost, and they have no way of knowing. The comment even acknowledges this is wrong.

**Fix:** Add a `.saveFailed` case to `SaveResult` and surface an alert in `ActiveSessionView`.

---

## 🟡 Design Problems

### 4. Double-insert on `addExercise` — relationship appended AND context-inserted

**File:** [RoutineViewModel.swift](file:///Users/samuelkouril/Desktop/WorkoutTracker1/ViewModels/RoutineViewModel.swift#L46-L53)

```swift
func addExercise(name: String, to routine: WorkoutRoutine, context: ModelContext) {
    // ...
    let exercise = RoutineExercise(name: trimmed, order: newOrder, routine: routine)
    context.insert(exercise)          // <-- inserts into SwiftData
    routine.exercises.append(exercise) // <-- also manually appends to the relationship
}
```

The `RoutineExercise` init already sets `self.routine = routine`, so SwiftData will automatically add it to `routine.exercises` when the context is saved. Manually appending may cause the exercise to appear **twice** in the `routine.exercises` array during the same run loop, leading to a doubled count in the UI until the next SwiftData sync. The same pattern exists in `SessionViewModel.startSession` (line 33: `routine.sessions.append(session)`).

> [!NOTE]
> This may not cause a visible bug today because SwiftData deduplicates by identity on save, but it's fragile and semantically incorrect. Pick one approach: either set the inverse relationship in the init (already done), or manually append — not both.

---

### 5. `WeightUnit` exists but is never used anywhere

**File:** [LoggedSet.swift](file:///Users/samuelkouril/Desktop/WorkoutTracker1/Models/LoggedSet.swift#L63-L94)

The `WeightUnit` enum has `display()`, `toKg()`, and `formatted()` methods, but:
- `ActiveSessionView` hard-codes `"kg"` in the previous-best display (line 152)
- `validateAndSave` stores the raw user input directly as `weightKg` without any unit conversion
- There is no `@AppStorage("weightUnit")` toggle anywhere

This means if a user enters weight in lbs (which they have no way to indicate), it's stored as kg. The entire `WeightUnit` type is dead code.

---

### 6. `previousLoggedSet` builds a full session list on every SwiftUI render

**File:** [RoutineExercise.swift](file:///Users/samuelkouril/Desktop/WorkoutTracker1/Models/RoutineExercise.swift#L57-L68)

This method is called from `ExercisePage.body` on every re-render (e.g. every keystroke in the text fields). It:
1. Maps ALL historical `loggedSets` into sessions
2. Filters and sorts them
3. Scans the sets again

For an exercise with hundreds of logged sets over time, this is O(n log n) **per keystroke**. It should be computed once in `onAppear` or cached in the ViewModel.

---

### 7. Discarding a session doesn't remove it from `routine.sessions`

**File:** [ActiveSessionViewModel.swift](file:///Users/samuelkouril/Desktop/WorkoutTracker1/ViewModels/ActiveSessionViewModel.swift#L122-L125)

```swift
func discardSession(session: WorkoutSession, context: ModelContext) {
    context.delete(session)
    // But routine.sessions still holds a reference to the deleted session
}
```

The `startSession` method in `SessionViewModel` manually appends to `routine.sessions`. When discarding, the code deletes from the context but doesn't remove from `routine.sessions`. Until SwiftData syncs, `routine.sortedSessions` in `DashboardView` may still show the deleted session or the session count may be wrong.

---

## 🔵 Minor Issues

### 8. `@Bindable` used on a non-`@Observable` binding target

**File:** [ActiveSessionView.swift](file:///Users/samuelkouril/Desktop/WorkoutTracker1/Views/Session/ActiveSessionView.swift#L125)

```swift
@Bindable var viewModel: ActiveSessionViewModel
```

`@Bindable` is designed for SwiftData `@Model` types or `@Observable` types passed as bindings from a parent. Here, `viewModel` is passed as a plain value from the parent's `@State`. This works because `ActiveSessionViewModel` is `@Observable`, but the idiomatic pattern would be to either pass it as a `Binding` or simply as `let` / `var` since `@Observable` types are reference types and mutations propagate automatically without `@Bindable`.

---

### 9. `onTapGesture` on `ExercisePage` conflicts with `TabView` page swiping

**File:** [ActiveSessionView.swift](file:///Users/samuelkouril/Desktop/WorkoutTracker1/Views/Session/ActiveSessionView.swift#L241-L243)

```swift
.onTapGesture {
    isFocused = false
}
```

Adding a tap gesture recognizer to the entire page content can interfere with the `TabView(.page)` swipe gesture recognizer and with tapping into text fields. A better approach is to use a `UITapGestureRecognizer` with `cancelsTouchesInView: false`, or use `.scrollDismissesKeyboard(.interactively)` on a `ScrollView`.

---

### 10. Nested `NavigationStack` when navigating from Dashboard to RoutineListView

**File:** [DashboardView.swift](file:///Users/samuelkouril/Desktop/WorkoutTracker1/Views/Dashboard/DashboardView.swift#L50)

```swift
NavigationLink(destination: RoutineListView()) {
    Label("Routines", systemImage: "list.bullet.clipboard")
}
```

`RoutineListView` wraps its own content in a `NavigationStack` (line 41 of RoutineListView.swift). Pushing it inside `DashboardView`'s `NavigationStack` creates a **double-nested** `NavigationStack`, which leads to double navigation bars and broken back-button behavior.

---

### 11. No input validation for negative or zero values

**File:** [ActiveSessionViewModel.swift](file:///Users/samuelkouril/Desktop/WorkoutTracker1/ViewModels/ActiveSessionViewModel.swift#L89-L91)

```swift
} else if let reps = Int(repsStr), let weight = Double(weightStr) {
    let set = LoggedSet(reps: reps, weightKg: weight, ...)
```

A user can enter `0` reps, `-5` weight, or `0.0001` kg and it will be saved as a valid set. There should be guards for `reps > 0` and `weight > 0`.

---

## Severity Summary

| # | Issue | Severity | Effort |
|---|-------|----------|--------|
| 1 | `previousLoggedSet` returns arbitrary set, not best | 🔴 Bug | Low |
| 2 | Only one set per exercise supported | 🔴 Design gap | Medium |
| 3 | Save failure silently returns success | 🔴 Bug | Low |
| 4 | Double-insert on relationship + context | 🟡 Fragile | Low |
| 5 | `WeightUnit` is dead code | 🟡 Dead code | Low |
| 6 | O(n log n) computation on every keystroke | 🟡 Perf | Low |
| 7 | Discard doesn't clean up routine.sessions | 🟡 Bug-adjacent | Low |
| 8 | Unnecessary `@Bindable` usage | 🔵 Style | Trivial |
| 9 | `onTapGesture` conflicts with page swiping | 🔵 UX | Low |
| 10 | Double-nested NavigationStack | 🔵 UI bug | Low |
| 11 | No validation for negative/zero values | 🔵 Validation | Trivial |

---

## What's Done Well

- **SwiftData relationships** are correctly set up with appropriate cascade delete rules
- **MVVM separation** is clean — ViewModels handle mutations, Views handle presentation
- **Code documentation** is thorough with clear MARK sections and doc comments
- **Preview providers** are well-crafted with seeded test data
- **Input trimming** is consistently applied before saving
- **Empty state views** using `ContentUnavailableView` are idiomatic and polished
