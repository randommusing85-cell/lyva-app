# Lyva — Technical Specification

This document describes the technical stack, architecture decisions, and build instructions for Lyva.

---

## Tech Stack

- Flutter (stable channel)
- Dart
- Android (primary platform)
- Firebase
  - Firebase Functions (AI calls, entitlement checks)
  - Firebase Remote Config (paywall modes, feature flags)
- Isar (offline-first local database)
- RevenueCat (subscriptions & entitlements)

---

## Architecture Overview

### Client (Flutter)
- Offline-first design using Isar
- Riverpod for state management
- Clear separation of:
  - free features
  - premium-gated features
- Minimal, uncluttered UI by default

### Backend (Firebase)
- Callable Cloud Functions for:
  - AI plan generation
  - AI coaching responses
  - premium feature enforcement
- Server-side entitlement verification to protect AI costs
- Remote Config used for:
  - paywall mode (OFF / SOFT / HARD)
  - beta feature toggles

---

## Entitlements & Monetisation

- RevenueCat is the single source of truth for:
  - subscription status
  - entitlement validity
- Entitlements are checked:
  - client-side (UX gating)
  - server-side (API access control)

---

## Local Data (Isar)

Current / planned collections include:
- UserProfile
  - **scheduledDays** (comma-separated string: "1,3,5" = Mon/Wed/Fri)
  - Helper methods for day list conversion and schedule checking
- PrimePlan (training + nutrition targets)
- CheckIn (weight, waist, adherence)
- WorkoutTemplate
- WorkoutSession
- FoodLog (simplified in early versions)

Schema is designed to:
- support progressive feature unlocks
- avoid migrations where possible
- remain offline-safe

---

## Workout Scheduling System

### Data Model
- **UserProfile.scheduledDays**: String field storing comma-separated day numbers (1=Mon, 7=Sun)
- **Helper methods**:
  - `scheduledDaysList`: Converts string to List<int>
  - `isScheduledWorkoutDay(DateTime)`: Checks if a date is a scheduled training day
  - `scheduleDisplayText`: Returns human-readable schedule (e.g., "Mon, Wed, Fri")

### Smart Miss Tracking
- **Completed workouts**: Marked green in calendar
- **Missed workouts**: Marked red ONLY if:
  - Day was in user's scheduled training days
  - No workout session was logged
  - Day is in the past
- **Rest days**: Show no color (no false negatives)
- **Today**: Blue border indicator

### UI Components
- **WorkoutDayScheduler**: Visual chip selector (Mon-Sun)
  - Enforces trainingDaysPerWeek limit
  - Shows progress indicator
  - Provides success confirmation
- **WorkoutCalendar**: Monthly calendar widget
  - Color-coded workout status
  - Stats badges (completed/missed counts)
  - Compact ~120px height

### Integration Points
- **Onboarding**: Required schedule selection before completion
- **Edit Profile**: Update schedule with validation
- **Settings**: Quick schedule adjustment dialog
- **Today's Workout Screen**: Calendar display with current month

---

## Getting Started

### Install dependencies
```bash
flutter pub get
```

### Generate Isar schema after UserProfile changes
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Build for Android
```bash
flutter build apk --release
```

---

## Feature Flags & Remote Config

Current configurable features:
- Paywall mode (OFF/SOFT/HARD)
- Beta feature toggles
- Workout calendar display options (planned)

---

## Performance Considerations

### Offline-First Design
- All workout data stored locally in Isar
- Calendar calculations performed client-side
- No network required for schedule management or calendar display

### Calendar Rendering
- Efficient date calculations using DateTime
- Minimal re-renders with Riverpod state management
- Compact widget tree for smooth scrolling

---

## Future Technical Enhancements

- Push notifications for scheduled workout days
- Calendar sync with device calendar (optional)
- Advanced workout session queries for full-month data retrieval
- Analytics tracking for schedule adherence patterns
