# PrimeForm

**Your AI Fitness Companion** — A smart fitness app designed specifically for women, with cycle-aware training, post-partum guidance, and AI-powered coaching.

Built by [KineticIQ](mailto:kineticiq.ai@gmail.com)

---

## Overview

PrimeForm takes a science-first approach to women's fitness. It generates personalized nutrition and workout plans using AI, adapts recommendations based on menstrual cycle phases and post-partum recovery status, and tracks progress across workouts, meals, and daily check-ins.

---

## Features

### AI-Powered Plan Generation
- Personalized nutrition plans with calorie and macro targets (protein, carbs, fat) based on your profile, goals, and activity level
- Custom workout programs tailored to your experience level, available equipment (gym, home dumbbells, or calisthenics), and training schedule
- AI coach that suggests adjustments to your plans based on your progress

### Women's Health Integration
- **Cycle-Aware Training** — Tracks menstrual cycle phases (menstrual, follicular, ovulation, luteal) and displays training guidance appropriate for each phase
- **Post-Partum Recovery** — Supports early, mid, and late post-partum stages with recovery-appropriate progressions
- **Diastasis Recti Awareness** — Flags exercises and provides guidance for users managing diastasis recti
- **Delivery Type Tracking** — Accounts for C-section vs. vaginal delivery in recovery recommendations

### Workout Tracking
- Daily workout view with exercise lists, sets, reps, and rest periods
- Exercise alternatives — swap any exercise for a suitable replacement
- Skip workout option with tracking
- Workout completion logging
- Calendar view of your training schedule
- Smart 14-day lock on plan regeneration to encourage consistency

### Nutrition Tracking
- Log meals by type (breakfast, lunch, dinner, snack) with full macro breakdown
- Daily calorie and macro progress vs. targets
- Edit and delete meal entries
- BMR/TDEE calculations using the Mifflin-St Jeor equation
- Caloric deficit/surplus tracking

### Daily Check-Ins
- Log weight, waist circumference, and daily steps
- Track mood and energy levels (5-point scale)
- Optional notes for context
- Historical data feeds into trends

### Trends & Progress
- Weight trend visualization
- Macro adherence tracking over time
- BMR and TDEE tracking
- Daily progress overview (calories, steps, workouts)

### Personalized Experience
- Animated splash screen with logo
- Guided setup flow — walks new users through nutrition plan generation, then workout plan generation
- Personalized greeting on the home screen based on time of day and usage patterns
- Dynamic motivational quotes
- Quick-action buttons for common tasks

### Notifications
- Daily check-in reminders at your preferred time
- Workout day reminders
- Cycle phase notifications (period start alerts)
- Fully configurable in settings

### Profile & Settings
- Comprehensive profile: name, age, sex, height, weight, fitness goals, experience level, equipment, training days
- Injury and limitation management with detailed notes
- Update workout schedule anytime
- Notification preferences
- About screen and feedback (via email)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Local Database | Isar |
| Backend | Firebase (Analytics, Cloud Functions, Firestore) |
| Notifications | flutter_local_notifications |
| AI | Firebase Cloud Functions (server-side) |

---

## Premium Roadmap

The following features are on the roadmap. Users can join the waitlist from within the app:

- **AI Coaching** — Personalized AI coaching conversations
- **AI Memory** — AI learns your patterns and gives smarter advice over time
- **Progress Photos** — Upload photos for AI body analysis and achievable celeb/character comparisons
- **Cycle Predictions** — AI-powered period cycle predictions and training adjustments
- **Advanced Analytics** — Detailed trends and deeper insights
- **Meal Scanner** — Scan meals for instant nutrition info
- **Custom Workouts** — Build your own workout routines
- **Export Data** — Export your progress data

---

## Getting Started

### Prerequisites
- Flutter 3.x or later
- Dart 3.x or later
- Firebase project configured

### Setup
```bash
# Install dependencies
flutter pub get

# Generate Isar models
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

---

## Contact

Questions or feedback? Reach us at **kineticiq.ai@gmail.com**
