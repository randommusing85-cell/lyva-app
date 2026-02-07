# PrimeForm

**A calm, intelligent fitness app focused on clarity, consistency, and long-term habit building.**

PrimeForm combines structured fitness principles with AI-assisted coaching to help users train, eat, and progress—without confusion, overwhelm, or obsession.

> **Current Status**: Alpha (active development)  
> **Platform**: Android (iOS-ready)  
> **Tech Stack**: Flutter, Firebase, Isar (offline-first)

---

## 📱 Screenshots

<table>
  <tr>
    <td><img src="docs/screenshots/home.jpg" width="200"/><br/><em>Home Dashboard</em></td>
    <td><img src="docs/screenshots/workout.jpg" width="200"/><br/><em>Today's Workout</em></td>
    <td><img src="docs/screenshots/nutrition.jpg" width="200"/><br/><em>Meal Tracking</em></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/plans.jpg" width="200"/><br/><em>AI-Generated Plans</em></td>
    <td><img src="docs/screenshots/trends.jpg" width="200"/><br/><em>Progress Trends</em></td>
    <td><img src="docs/screenshots/settings.jpg" width="200"/><br/><em>Profile Settings</em></td>
  </tr>
</table>

---

## 🎯 Product Philosophy

**What PrimeForm believes:**
- Consistency matters more than precision
- Habits come before optimization
- Calm guidance beats aggressive motivation
- Trends matter more than daily noise
- AI should guide and encourage—not judge or shame

**What PrimeForm is NOT:**
- Not a calorie database race
- Not a social fitness platform
- Not a "30-day transformation" app
- Not an analytics overload tool

---

## ✨ Implemented Features

### 🏋️ Training System
- ✅ **AI-Generated Workout Plans**
  - Personalized based on experience level (beginner/intermediate/advanced)
  - Equipment-specific (gym/home dumbbells/bodyweight)
  - Configurable training frequency (3-6 days/week)
  - Injury/limitation-aware exercise selection
  
- ✅ **Smart Workout Scheduling**
  - Visual day selector (Mon-Sun chips)
  - Enforces training days/week limit
  - Schedule validation before plan generation
  
- ✅ **Workout Tracking**
  - Today's workout view with exercise details
  - Set/rep tracking with rest timers
  - Progress checkboxes per exercise
  - Workout completion logging
  
- ✅ **Workout Calendar** *(Coming to screenshots)*
  - Monthly calendar with workout history
  - Green circles = completed workouts
  - Red circles = missed scheduled workouts (NOT rest days)
  - Blue border = today
  - Stats badges (completed/missed counts)
  
- ✅ **14-Day Plan Lock**
  - Prevents constant program-hopping
  - Enforces consistency before regeneration
  - Countdown indicator shows days remaining

### 🍽️ Nutrition System
- ✅ **AI-Generated Nutrition Plans**
  - Personalized calorie and macro targets
  - Based on goals (cut/recomp/bulk)
  - Activity-level aware
  - TDEE calculation with activity multipliers
  
- ✅ **Meal-Based Tracking**
  - Log by meal (breakfast/lunch/dinner/snacks)
  - Simple macro entry (protein/carbs/fat)
  - Auto-calculated calories
  - Daily macro totals with progress bars
  - Color-coded progress (red/orange/blue for P/C/F)
  
- ✅ **Weekly Nutrition Analytics**
  - 7-day adherence score (%)
  - Per-macro adherence breakdown
  - "Keep going" encouragement messaging
  - Days logged counter

### 🤖 AI Coaching
- ✅ **Nutrition Adjustment Coach**
  - Analyzes 14-day weight/waist trends
  - Provides conservative adjustment recommendations
  - Prevents impulsive changes (7-day coach lock)
  - Plain-language explanations
  - Data-driven, not emotional
  
- ✅ **Trend Interpretation**
  - "Stay the course" vs "Adjust" guidance
  - Week-over-week comparisons
  - Acknowledges data variability
  
- ✅ **Plan Explanation**
  - AI explains workout programming
  - Nutrition target rationale
  - Accessible through "AI Coach" button

### 📊 Progress Tracking
- ✅ **Daily Check-Ins**
  - Weight tracking
  - Waist measurement
  - Daily steps
  - Optional notes
  - Simple, fast logging UI
  
- ✅ **Trends Dashboard**
  - Last 7 days rolling averages
  - Week-over-week comparison indicators
  - Visual trend cards (weight/waist/steps)
  - Recent check-in history

### 👩 Women's Health Features
- ✅ **Menstrual Cycle Tracking**
  - 4-phase cycle awareness (menstrual/follicular/ovulation/luteal)
  - Phase-specific training guidance
  - Energy level context
  - Educational content per phase
  - Configurable cycle length
  - Toggle on/off in settings
  
- ✅ **Post-Partum Support** *(Not shown in screenshots)*
  - Timeline-aware guidance (early/rebuilding/strengthening)
  - Exercise safety checks
  - Red flag warnings
  - Medical clearance requirements
  - Diastasis recti awareness

### ⚙️ Settings & Customization
- ✅ **Profile Management**
  - Age, sex, height, weight
  - Fitness goals (fat loss/recomp/muscle gain)
  - Experience level (beginner/intermediate/advanced)
  - Equipment access
  - Training frequency
  
- ✅ **Injury/Limitation Management** *(Not shown in screenshots)*
  - Predefined injury selector
  - Custom notes
  - AI-aware exercise substitutions
  
- ✅ **Notification Settings** *(Not shown in screenshots)*
  - Check-in reminders
  - Workout day reminders
  - Customizable reminder times
  
- ✅ **Medical Disclaimer**
  - Prominent safety warnings
  - Especially for women's health features

### 📱 App Infrastructure
- ✅ **Offline-First Architecture**
  - Works without internet connection
  - Isar local database
  - Firebase sync when online
  - No data loss on poor connectivity
  
- ✅ **Onboarding Flow**
  - Profile setup wizard
  - Goal selection
  - Equipment questionnaire
  - Cycle/post-partum questionnaire (women)
  - Generates first plans automatically
  
- ✅ **Bottom Navigation**
  - Home (today's overview with weekly progress)
  - Plans (nutrition + workout details)
  - Trends (analytics dashboard)
  - Settings (profile management)
  
- ✅ **Analytics Integration**
  - Firebase Analytics
  - Event tracking for validation
  - User behavior insights
  - Funnel analysis capability

### 🎨 Design & UX
- ✅ **Calm, Minimal Interface**
  - Clean typography
  - Soft color palette (blue/purple/green)
  - Generous whitespace
  - Clear visual hierarchy
  
- ✅ **Encouraging Messaging**
  - "Welcome back"
  - "Let's stay consistent today"
  - "Keep going. Consistency compounds."
  - No shame, no guilt
  
- ✅ **Phase Indicators**
  - "Building Phase" badge with day counter
  - Context-appropriate guidance
  - Visual progress feedback

---

## 🚧 Planned Features

### Phase 1 Completion (Target: Q1 2025)
- [ ] Workout calendar with missed workout indicators
- [ ] Internal beta testing (5-10 users)
- [ ] Bug fixes and UX refinement
- [ ] Performance optimization
- [ ] User validation (5+ retained, $30/mo willingness to pay)

### Phase 2 - Monetization (Target: Q2 2025)
- [ ] RevenueCat subscription integration
- [ ] Soft paywall implementation
- [ ] Premium tier features:
  - Advanced macro tracking (carb/fat cycling)
  - Custom exercises
  - Progress photos with AI feedback
  - MCP (Model Context Protocol) for contextual coaching
  - Extended plan history

### Phase 3 - Advanced Features
- [ ] Apple Watch / Health app integration
- [ ] Barcode scanning for food logging
- [ ] Singapore hawker food database
- [ ] Progressive overload tracking
- [ ] Multi-week periodization
- [ ] Workout templates library

---

## 🛠️ Tech Stack

**Frontend:**
- Flutter (Dart) - cross-platform framework
- Riverpod - state management
- Isar - offline-first local database
- Go Router - navigation

**Backend:**
- Firebase Functions - serverless compute
- Firebase Analytics - product analytics
- Firebase Remote Config - feature flags
- OpenAI API - AI coaching and plan generation

**Platform:**
- Android (primary, production-ready)
- iOS (configured, TestFlight-ready)

**Architecture:**
- Offline-first data persistence
- RESTful API design for Firebase Functions
- Provider pattern for dependency injection
- Repository pattern for data access

---

## 📦 Getting Started

### Prerequisites
- Flutter SDK (stable channel, ≥3.0.0)
- Dart SDK
- Android Studio or VS Code
- Firebase CLI
- Android device or emulator (API 21+)

### Installation

```bash
# Clone the repository
git clone https://github.com/randommusing85-cell/primeform-app-android.git
cd primeform-app-android

# Install dependencies
flutter pub get

# Generate Isar schema files
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app (debug mode)
flutter run

# Build release APK
flutter build apk --release
```

### Firebase Setup

This app requires Firebase configuration:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android app to your Firebase project
3. Download `google-services.json` → place in `android/app/`
4. (Optional) Add iOS app and download `GoogleService-Info.plist` → place in `ios/Runner/`
5. Deploy Firebase Functions:
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

**Required Firebase services:**
- Authentication (Anonymous auth enabled)
- Cloud Functions (for AI calls)
- Analytics
- Remote Config (for feature flags)

---

## 🗂️ Project Structure

```
lib/
├── core/               # Core utilities, constants
├── features/           # Feature modules
│   ├── auth/          # Authentication
│   ├── profile/       # User profile management
│   ├── nutrition/     # Meal logging, nutrition plans
│   ├── workout/       # Workout tracking, exercise library
│   ├── check_in/      # Daily check-ins, trends
│   └── settings/      # App settings
├── models/            # Isar data models
├── providers/         # Riverpod providers
└── main.dart          # App entry point
```

---

## 🎯 Target Users

- **Beginners** who feel lost and need structured guidance
- **Post-injury restarters** rebuilding fitness foundation
- **Busy adults (30s-40s)** who want results without micromanagement
- **Women** seeking cycle-aware or post-partum fitness support
- **Systematic learners** who value understanding over arbitrary rules

---

## 📊 Product Validation

**Current Status (as of Jan 2025):**
- Alpha testing phase
- Active development: 12+ hrs/week
- Target validation: April 1, 2025

**Success Criteria:**
- 5+ users remain actively engaged
- Users express willingness to pay $30/month
- Positive feedback on core value proposition

**If validation fails:**
- Project stops entirely (no pivot)
- Learning captured for future projects

---

## 🧭 Product Philosophy & Roadmap

See detailed documentation:
- [PRODUCT_SPEC.md](PRODUCT_SPEC.md) - Feature roadmap, product philosophy
- [TECH_SPEC.md](TECH_SPEC.md) - Technical architecture, implementation details

---

## 📄 License

Private repository - all rights reserved.

This is a personal project and portfolio piece. Not currently open for contributions.

---

## 👤 Author

**Kenneth Sam**

Building PrimeForm as part of:
- M.Sc. Computer Science (Industry 4.0) - National University of Singapore
- Personal fitness journey and recovery from medical setbacks
- Product validation exercise for entrepreneurial path

**Connect:**
- LinkedIn: [linkedin.com/in/kennethsam1230](https://linkedin.com/in/kennethsam1230)
- Email: E1124348@u.nus.edu

---

## 🙏 Acknowledgments

**Built with:**
- OpenAI API for AI coaching and plan generation
- Firebase for backend infrastructure
- Flutter community for excellent framework and packages
- Personal trainer certification knowledge for exercise programming
- 2+ years of personal fitness recovery experience

---

## 📝 Notes

**Why "PrimeForm"?**
- "Prime" = optimal state, first-class quality
- "Form" = physical shape + proper technique
- Together: achieving your optimal physical state through proper fundamentals

**Design Inspiration:**
- MyFitnessPal (logging simplicity)
- MacroFactor (trend-based adjustments)
- Strong app (workout tracking)
- Headspace (calm, encouraging tone)

But differentiated by:
- AI-first coaching approach
- Women's health integration
- Systematic learner focus
- Anti-obsession philosophy
