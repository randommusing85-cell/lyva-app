# Lyva - What's Next? 🚀

## 📊 Current State (v0.1 - January 2026)

### ✅ What We Have Built

**Core Foundation:**
- ✅ Complete Flutter app architecture (Riverpod + Isar + Firebase)
- ✅ Offline-first database with reactive streams
- ✅ 50+ Firebase Analytics events tracking
- ✅ User profile with onboarding flow
- ✅ Settings & profile editing

**Nutrition System:**
- ✅ AI-generated nutrition plans (calories + macros)
- ✅ Meal-based macro tracking (breakfast/lunch/dinner/snacks)
- ✅ Daily macro adherence calculations
- ✅ 14-day plan lock (consistency over optimization)
- ✅ AI Coach for data-driven adjustments (7-day lock)

**Workout System:**
- ✅ AI-generated workout plans (3-6 days/week)
- ✅ Equipment-specific programming (gym/home/bodyweight)
- ✅ Experience-based progression (beginner/intermediate/advanced)
- ✅ Today's Workout screen with exercise details
- ✅ Rest timers for each exercise
- ✅ Workout completion tracking
- ✅ 14-day workout plan lock
- ✅ **Full month workout calendar with navigation** ⭐ NEW
- ✅ **Tappable workout history viewer** ⭐ NEW
- ✅ **Smart miss tracking (scheduled days only)** ⭐ NEW

**Women's Health Features:**
- ✅ Menstrual cycle tracking with phase calculation
- ✅ Cycle-aware training guidance
- ✅ Post-partum exercise safety protocols
- ✅ Post-partum phase tracking (0-18 months)
- ✅ Medical clearance requirements
- ✅ Diastasis recti awareness
- ✅ Injury/limitation tracking

**Progress Tracking:**
- ✅ Daily check-ins (weight, waist, steps, notes)
- ✅ Trends screen with 7-day averages
- ✅ Weekly workout progress card
- ✅ Macro adherence visualization

**Deployment:**
- ✅ TestFlight ready (iOS)
- ✅ Android APK build configuration
- ✅ Privacy policy & terms of service
- ✅ Comprehensive analytics tracking

---

## 🎯 Immediate Next Steps (v0.1 → v0.2)

### Priority 1: Internal Testing & Validation (Week 1-2)

**Goal:** Validate core loop with real users

#### Testing Checklist:
```
📋 User Acceptance Testing
□ Test complete onboarding flow
□ Generate nutrition plan → Track meals for 7 days
□ Generate workout plan → Complete 3 workouts
□ Test daily check-ins for consistency
□ Verify calendar shows workout history correctly
□ Test workout completion flow end-to-end
□ Test AI Coach after 7 days
□ Verify 14-day plan locks work
□ Test cycle tracking calculations
□ Test post-partum guidance
□ Verify notification system
□ Test offline functionality
□ Check analytics events fire correctly

🐛 Bug Hunting
□ Find any crashes or errors
□ Test edge cases (empty states, no internet, etc.)
□ Check UI on different screen sizes
□ Test with real menstrual cycle data
□ Verify post-partum calculations
□ Test injury selector edge cases

💬 Feedback Collection
□ Is the onboarding clear?
□ Are the plan locks frustrating or helpful?
□ Is the AI Coach useful?
□ Is the calendar intuitive?
□ Is meal logging too tedious?
□ What features are missing?
□ Where do users get stuck?
```

**Action Items:**
1. Deploy to 3-5 internal testers (friends/family)
2. Create feedback form (Google Forms or Typeform)
3. Schedule 1-week check-in calls
4. Track usage with Firebase Analytics
5. Document all bugs in GitHub Issues

---

### Priority 2: Critical Bug Fixes & Polish (Week 2-3)

**Based on Internal Testing Feedback:**

#### Expected Issues to Fix:
```
🔧 Likely Fixes Needed:
□ Add "Edit Meal" functionality (currently can only delete)
□ Add workout notes/feedback field
□ Improve error messages
□ Add loading states for AI generation
□ Better empty states (no plan, no meals, etc.)
□ Add "Skip Workout" functionality with reason
□ Improve calendar performance with large datasets
□ Add pull-to-refresh on key screens
□ Better offline sync indicators
□ Add confirmation dialogs for destructive actions

🎨 UI/UX Polish:
□ Consistent spacing and padding
□ Better icon choices
□ Improve color contrast for accessibility
□ Add haptic feedback for important actions
□ Better error state illustrations
□ Add onboarding tooltips for key features
□ Improve calendar tap feedback
□ Add skeleton loaders
```

---

### Priority 3: Missing Provider (Critical)

**⚠️ URGENT:** `weeklyMacroTotalsProvider` is referenced but not implemented!

**File:** `lib/state/providers.dart`

**Add this provider:**
```dart
final weeklyMacroTotalsProvider = FutureProvider.autoDispose<List<DailyMacroTotal>>((ref) async {
  final repo = ref.watch(lyvaRepoProvider);
  return repo.getDailyMacroTotals(7); // Last 7 days
});
```

**This fixes:** `MacroAdherenceCard` on home screen

---

## 🚀 v1.0 Launch Preparation (Week 4-8)

### Phase 1: Public Free Tier

**Goal:** Ship minimal viable product to real users

#### Feature Set for v1.0:
```
✅ Core Features (Already Built):
- Onboarding & profile setup
- AI-generated nutrition plan
- AI-generated workout plan  
- Meal logging
- Workout tracking with calendar
- Daily check-ins
- Trends visualization
- Cycle tracking (women)
- Post-partum guidance (women)
- Basic settings

🆕 Add Before Launch:
□ Better onboarding tutorial (first-time user experience)
□ Sample plans (preview before signup)
□ Social proof (testimonials, if available)
□ Help documentation/FAQ
□ In-app support (feedback button)
□ App rating prompt (after 2 weeks of use)
□ Share progress feature (optional)
□ Export data feature (privacy/GDPR)
```

#### Home Screen (3-Element Philosophy):
```
1. Today's Workout Card (done ✅)
2. Daily Check-in Card (done ✅)
3. Macro Adherence Card (needs weeklyMacroTotalsProvider)

Keep it SIMPLE. No overwhelming dashboard.
```

#### Pre-Launch Checklist:
```
📱 Technical
□ App Store screenshots (5-6 images)
□ App Store description & keywords
□ App icon finalized (1024x1024)
□ Test on multiple devices (small/large screens)
□ Performance optimization (reduce APK/IPA size)
□ Crash reporting setup (Firebase Crashlytics)
□ Rate limiting on Firebase Functions
□ Security review (sensitive data handling)

📄 Legal
□ Privacy Policy (done ✅)
□ Terms of Service (done ✅)
□ GDPR compliance (data export/deletion)
□ Medical disclaimer (done ✅)
□ Age restriction (13+ / 18+?)

📊 Analytics
□ Define success metrics (DAU, retention, plan adherence)
□ Set up funnels (onboarding, plan generation, workout completion)
□ Dashboard for monitoring (Firebase/Mixpanel)

🎯 Marketing
□ Landing page (optional but recommended)
□ Beta tester testimonials
□ Social media presence (Instagram/TikTok for fitness)
□ Reddit r/xxfitness, r/fitness posts
□ Product Hunt launch (optional)
```

---

## 💰 Phase 2: Paid Tier Introduction (Post-Launch)

### Premium Features ($6/month)

**Goal:** Monetize power users who want more depth

```
🔓 Premium Unlocks:
□ Advanced macro tracking
  - Micronutrient tracking
  - Meal timing optimization
  - Pre/post-workout meal suggestions
  - Singapore hawker food database (moat!)

□ AI Coaching Conversations
  - Chat interface with AI coach
  - Context-aware advice (knows full history)
  - Form check reminders
  - Deload week suggestions
  - Plateau breaking strategies

□ Advanced Analytics
  - Body composition trends
  - Volume progression tracking
  - Fatigue management scores
  - Predicted strength gains
  - Cycle phase performance correlation

□ Customization
  - Custom workout templates
  - Exercise library additions
  - Meal templates/favorites
  - Multiple plan versions (A/B testing)

□ Export & Integration
  - PDF workout logs
  - CSV data export
  - Apple Health sync
  - Google Fit sync
  - MyFitnessPal integration
```

**Implementation:**
- Use **RevenueCat** (already integrated!)
- Remote paywall configuration (already set up!)
- A/B test pricing ($4.99 vs $6.99)
- Offer annual discount (2 months free)
- Free trial: 7 days or 14 days?

---

## 🎯 Phase 3: Identity & Motivation Layer

### The "Boring Middle" Problem

**Issue:** Weeks 4-12 are where most users drop off
- Initial excitement fades
- Progress slows down
- Habits not yet automatic
- No visible transformation yet

**Solution:** Identity-based features

```
🏆 Achievement System (Non-Gamified):
□ Consistency streaks
  - "14 days of check-ins"
  - "4 weeks on same plan" (anti-optimization badge)
  - "Completed a full cycle of training"

□ Milestones (not PRs)
  - "First month complete"
  - "Survived the boring middle"
  - "100 workouts logged"
  - "365 days of tracking"

□ Identity Reinforcement
  - "You're someone who shows up"
  - "You're building the habit"
  - Progress photos (optional, private)
  - Reflection prompts (weekly)

□ Community (Optional)
  - Anonymous progress sharing
  - "Others like you are doing X"
  - Accountability partners (opt-in)
  - Private support groups (menstrual/postpartum)
```

---

## 🔮 Long-Term Vision (6-12 months)

### 1. MCP Integration (Premium Differentiator)

**Model Context Protocol** for AI coaching

**What it enables:**
- AI coach that remembers EVERYTHING
- Contextual advice based on full history
- "You struggled with squats 3 weeks ago, how's it going?"
- Longitudinal pattern recognition
- Truly personalized coaching

**Implementation:**
- Requires backend infrastructure
- Store conversation history
- Context window management
- Privacy considerations (user data)

**This is your MOAT.** No other fitness app has this.

---

### 2. Singapore-Specific Features (Competitive Moat)

**Hawker Food Database:**
```
□ Macro data for 100+ local dishes
  - Chicken rice (white/brown/roast)
  - Char kway teow
  - Nasi lemak
  - Laksa
  - Roti prata
  - Ban mian
  - Economic rice (mixed dishes)
  - etc.

□ Location-based suggestions
  - "Hawker centers near you"
  - "High-protein options at X hawker"

□ Meal prep for Singaporean context
  - Meal prep services integration
  - Budget-friendly options
  - Catering recommendations
```

**Why it matters:**
- Every other fitness app is US-centric
- Singaporeans struggle to track local food
- This is YOUR competitive advantage
- Local apps are poorly designed
- You understand the market

---

### 3. Advanced Women's Health

```
□ PCOS management protocols
□ Perimenopause training adjustments  
□ Pregnancy-safe workout modifications
□ Breastfeeding nutrition support
□ Return-to-running post-partum program
□ Pelvic floor PT exercise library
□ Integration with wearables (Oura, Whoop) for cycle tracking
```

---

## 📈 Success Metrics

### v0.1 (Internal Testing)
- **Goal:** 5 users complete 2 weeks
- **Success:** 80% retention, <5 critical bugs
- **Timeline:** 2 weeks

### v1.0 (Public Launch)
- **Goal:** 100 downloads in month 1
- **Success:** 40% complete onboarding, 20% week-2 retention
- **Timeline:** 2 months

### Phase 2 (Paid Tier)
- **Goal:** 5% conversion to paid
- **Success:** $300 MRR (50 paid users)
- **Timeline:** 6 months

### Phase 3 (Growth)
- **Goal:** 1,000 MAU, $1,000 MRR
- **Success:** Product-market fit validated
- **Timeline:** 12 months

---

## 🎯 Immediate Action Plan (This Week)

### Day 1-2: Fix Critical Issues
```bash
□ Add weeklyMacroTotalsProvider to providers.dart
□ Test macro adherence card displays correctly
□ Fix any remaining build errors
□ Deploy to TestFlight (new build)
□ Test on real device end-to-end
```

### Day 3-4: Prepare for Testing
```bash
□ Create feedback form
□ Write testing instructions
□ Recruit 3-5 testers
□ Set up weekly check-in calls
□ Create GitHub Issues board for bugs
```

### Day 5-7: Documentation
```bash
□ Write user guide / FAQ
□ Document known issues
□ Create troubleshooting guide
□ Update README on GitHub
□ Add screenshots to repo
```

---

## 🚨 Critical Decisions Needed

### 1. **Free vs Paid Strategy**
- Launch 100% free initially?
- Or launch with paid tier from day 1?
- **Recommendation:** Start free, add paid after validation

### 2. **Target Audience**
- Focus on women only? (current design)
- Or open to all genders?
- **Recommendation:** Market to women, but don't restrict men

### 3. **Geographic Focus**
- Singapore-first (hawker food moat)?
- Or global from start?
- **Recommendation:** Global app, Singapore features as premium/unique

### 4. **AI Features**
- Keep simple AI (current)?
- Or invest in MCP for premium tier?
- **Recommendation:** Validate product first, then add MCP

---

## 💡 Key Insights from Your Philosophy

**"Consistency over precision"**
- ✅ Your 14-day plan locks enforce this
- ✅ Macro tracking is meal-based (not tedious)
- ✅ Calendar shows consistency patterns

**"Calm guidance over aggressive motivation"**
- ✅ No push notifications spam
- ✅ No "crushing it" language
- ✅ Post-partum safety focus
- ⚠️ Need to maintain this in future features

**"Boring middle is the real challenge"**
- ❌ Not addressed yet
- 🎯 This is your Phase 3 focus

**"Singapore context as moat"**
- ❌ Not implemented yet
- 🎯 This is your Phase 2 premium feature

---

## 🎯 The Next 90 Days

### Month 1: Validation
- Week 1-2: Internal testing
- Week 3-4: Bug fixes + polish

### Month 2: Launch Prep
- Week 5-6: App Store submission prep
- Week 7-8: Soft launch to small audience

### Month 3: Growth
- Week 9-10: Public launch
- Week 11-12: Iterate based on feedback

---

## ✅ Your Current Position

**You have:**
- ✅ Solid technical foundation
- ✅ Unique positioning (women's health + Singapore)
- ✅ Clear philosophy (consistency over optimization)
- ✅ MVP features complete
- ✅ Deployment-ready code

**You need:**
- 🎯 Real user validation
- 🎯 Bug fixing from real usage
- 🎯 Monetization strategy execution
- 🎯 Marketing presence

**You're at the perfect inflection point:** Ship to real users now, iterate based on feedback, then monetize.

---

## 🚀 My Recommendation: SHIP IT

**Stop building, start validating.**

1. Fix the `weeklyMacroTotalsProvider` bug (5 minutes)
2. Deploy to TestFlight (today)
3. Get 5 people using it this week
4. Collect brutal feedback
5. Iterate fast
6. Launch publicly in 4 weeks

**You've built enough. Time to test it with real humans.** 💪

The most important feature you can build now is **getting real users** to validate your assumptions.

---

**What do you want to tackle first?** 🎯
