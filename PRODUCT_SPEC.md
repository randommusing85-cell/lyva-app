# Lyva  
*A calm, intelligent fitness system for consistency over confusion*

---

## Overview

Lyva is a fitness and nutrition app designed to reduce confusion, overwhelm, and decision fatigue—especially for beginners, restarters, and busy adults.

Rather than chasing perfect accuracy or extreme optimisation, Lyva prioritises:
- consistency
- clarity
- conservative, safe guidance
- long-term habit building

The app combines structured fitness principles with AI-assisted coaching, while deliberately avoiding cluttered dashboards, social feeds, and obsession-driven mechanics.

---

## Product Philosophy

**What Lyva believes**
- Consistency matters more than precision
- Habits come before optimisation
- Calm guidance beats aggressive motivation
- Trends matter more than day-to-day noise
- AI should interpret and guide—not judge or shame

**What Lyva is not**
- Not a calorie database race
- Not a social fitness platform
- Not a "30-day shredded" app
- Not an analytics overload tool

---

## Target Users

- Beginners who feel lost
- People restarting fitness in their 30s–40s
- Users overwhelmed by conflicting advice
- Users who "know what to do" but struggle with consistency
- Working adults who want guidance without obsession

---

## Monetisation & Control

- RevenueCat is used for subscriptions and entitlements
- Paywall modes are remotely configurable:
  - **OFF** – full access (beta/testing)
  - **SOFT** – limited premium usage
  - **HARD** – premium locked behind subscription
- Entitlements are checked:
  - client-side (UI/UX gating)
  - server-side (AI cost protection)
- Paywall can be toggled without rebuilding the app

---

# Feature Roadmap

---

## v0.1 — Foundation Build (Internal / Beta)

**Purpose:**  
Validate the core loop and architecture. No monetisation pressure.

### Core Architecture
- User profile:
  - age, sex, height, weight
  - training level
  - **scheduled workout days (specific days: Mon-Sun)**
- Goal selection:
  - fat loss
  - recomposition
  - muscle gain
- Equipment selection:
  - gym
  - home
  - dumbbells
  - bodyweight
- Training days per week
- Entitlements system (RevenueCat-ready)

---

### Nutrition (v0.1)
- AI-generated daily calorie target
- AI-generated protein target
- Simple food logging:
  - generic foods
  - portion-based estimation
- End-of-day compliance check (yes/no + notes)
- No forced full macro tracking

---

### Workouts (v0.1)
- AI-generated workout plans:
  - exercises
  - sets
  - reps
- **Workout day scheduler:**
  - Visual day picker (Mon-Sun chips)
  - Enforces training days/week limit
  - Validates selection before plan generation
- **Smart workout calendar:**
  - Visual progress tracking
  - Green circles = completed workouts
  - Red circles = missed scheduled workouts (NOT rest days)
  - Blue border = today
  - Stats badges showing completed/missed counts
- Workout session logging
- Session completion tracking
- Fixed, curated exercise list

**Key UX Philosophy:**
- Calendar only marks SCHEDULED days as potential misses
- Rest days never show as "missed" (no false negatives)
- Promotes accurate adherence tracking
- Reduces guilt from unscheduled rest days

---

### Check-ins & Trends (v0.1)
- Weekly check-in:
  - body weight
  - waist measurement
  - adherence %
- Simple AI trend interpretation:
  - "stay the course"
  - "don't adjust yet"
- No aggressive auto-adjustments

---

### UI / UX (v0.1)
- Clean, minimal interface
- No cluttered dashboards
- Clear primary actions
- Calm, neutral tone
- **Visual workout progress indicators**
- **Color-coded adherence feedback**

---

## v1.0 — Public Free Tier (Habit Builder)

**Purpose:**  
Help users stay consistent without overwhelm.

---

### Nutrition (Free Tier)
- Calories + protein as primary focus
- Carbs/fats hidden or deemphasised
- Simple food logging UX
- No daily calorie changes
- Weekly check-in feedback only

---

### Home Screen (Free Tier)
Exactly **three core elements**:
1. Calories/macros so far  
2. Calories/macros remaining  
3. Log food  

**Plus:**
- Weekly workout progress indicator
- Current training schedule display
- Today's workout quick access

All analytics, trends, and insights:
- live in secondary tabs
- optional to view

---

### Workouts (Free Tier)
- Structured workout plans
- **Flexible workout scheduling (any days of week)**
- **Visual calendar with progress tracking**
- Workout logging
- Limited custom exercises
- Standard tracking mode:
  - weight + reps
- No advanced progression logic

---

### AI Coaching (Free Tier)
- Explains plans in plain language
- Encourages consistency
- Conservative guardrails
- No body critique
- No extreme recommendations
- **Schedule-aware feedback** (recognizes planned rest days vs. missed workouts)

---

## Phase 2 — Paid Tier (Power & Precision)

**Purpose:**  
Unlock depth *after* habits are established.

---

### Advanced Scheduling (Paid)
- **Multi-week workout schedules:**
  - Deload weeks
  - Periodization patterns
  - Different schedules per training phase
- **Schedule templates:**
  - Save/load common patterns
  - Share schedules (community feature)
- **Smart rescheduling:**
  - AI suggests makeup days for missed workouts
  - Flexible week rollover
- **Calendar integrations:**
  - Sync to device calendar
  - Google Calendar export
  - Outlook integration

---

### Advanced Nutrition (Paid)
- Full macro control (carbs / fats / protein)
- Training-day vs rest-day targets
- Weekly adaptive calorie algorithm (MacroFactor-style)
- Diet breaks and fatigue-aware logic
- Local food support (SG context):
  - hawker foods
  - local drinks
  - NTUC / local bentos
- Barcode scanning (Open Food Facts + extensions)

---

### Advanced Workouts (Paid)
- Unlimited custom exercises
- Per-exercise tracking modes:
  - weight + reps
  - weight + distance
  - reps + time
  - weight + time
  - distance + time
- Progressive overload tracking
- Historical bests
- Optional plateau detection
- **Advanced calendar analytics:**
  - Adherence trends over time
  - Weekly/monthly/yearly views
  - Pattern recognition (e.g., "you often miss Mondays")

---

### Scheduling & Automation (Paid)
- Scheduled workouts
- Guided workout sessions
- Exercise sequencing:
  - circuits
  - supersets
- Reduced manual interaction during workouts
- **Push notifications for scheduled workout days**
- **Adaptive rest day suggestions based on recovery**

---

### Integrations (Paid)
- Apple Health / Apple Watch sync
- Garmin sync
- Strava / Runkeeper data import
- No double data entry
- Battery-efficient background behaviour

---

### UI / UX Enhancements (Paid)
- Polished, modern UI
- Subtle, pleasant animations
- Optional dashboard customisation
- Minimal by default
- **Advanced calendar visualizations:**
  - Heatmaps
  - Streak tracking
  - Year-in-review summaries

---

## Phase 3 — Identity & Motivation Layer (Premium Differentiator)

---

### Aspiration Archetypes
- Users select preferred celebrities or fictional characters
- AI suggests a realistic archetype range based on:
  - body frame
  - habits
  - timeline
- Framed as trajectory, not comparison
- "Closest path to X-style physique"

---

### Progress Photo Check-ins (Paid)
- Optional photo uploads
- Face & background blur by default
- Pose & lighting guidance
- AI feedback focuses on:
  - consistency
  - trend direction
  - encouragement
  - practical next steps
- No ratings
- No harsh critique
- Tone selectable:
  - Coach
  - Neutral
  - Encouraging

---

### Women-Specific Intelligence (Optional, Paid)
- Menstrual cycle awareness
- Cycle-based trend interpretation
- Training intensity suggestions
- Nutrition guidance by cycle phase
- **Smart scheduling recommendations:**
  - Suggests scheduling heavy training during follicular phase
  - Recommends lighter training during luteal/menstrual phases
  - Adjusts "missed workout" tolerance during period week
- Insight-only (no medical claims)

---

## Design Principles for Workout Scheduling

### Free Tier Philosophy
- **Simple, clear day selection** (Mon-Sun chips)
- **Visual progress feedback** (calendar with colors)
- **Honest adherence tracking** (only scheduled days count as misses)
- **No guilt trips** (rest days are never marked as "missed")
- **Encouragement focus** ("You hit 3/4 workouts this week!")

### Paid Tier Enhancement Philosophy
- **Advanced patterns** (periodization, deloads)
- **Predictive insights** ("You typically struggle on Mondays")
- **Flexible adjustments** (easy rescheduling, AI suggestions)
- **Long-term visualization** (trends, streaks, annual summaries)
- **Never overwhelming** (still calm, still encouraging)

---

## Long-Term Vision

Lyva aims to become:
> A trusted, calm fitness companion people rely on—like MyFitnessPal for logging, but personalised, humane, and intelligent.

The app is designed to grow with the user:
- simple when they need structure
- powerful when they're ready for control
- always grounded in safety and realism

**Core Differentiator:**  
Unlike apps that guess your schedule or create false guilt, Lyva knows *exactly* when you planned to train and measures consistency against *your* plan—not an arbitrary standard.
