# Lyva v0.1 - Tester Guide

## 📱 Installation Instructions

### Step 1: Download the APK
- **Option A:** Download from GitHub release link (will be provided)
- **Option B:** Download from email attachment
- Save the file: `Lyva-v0.1.0-beta.apk`

### Step 2: Enable Installation from Unknown Sources

**Android 8.0 and newer:**
1. Try to install the APK
2. When prompted, tap "Settings"
3. Enable "Allow from this source"
4. Go back and tap "Install"

**Android 7.x and older:**
1. Go to **Settings** → **Security**
2. Enable **"Unknown sources"**
3. Tap "OK" when warned

**Note:** This is safe! You're installing a test app from a trusted developer. You can disable this after installation.

### Step 3: Install
1. Open the downloaded APK file from your Downloads folder
2. Tap **"Install"**
3. Wait for installation to complete (10-30 seconds)
4. Tap **"Open"** or find **"Lyva"** in your app drawer

### Step 4: Delete Old Version (If Applicable)
If you previously had Lyva installed:
1. Long-press the Lyva app icon
2. Tap "Uninstall" or drag to trash
3. Then install the new APK

---

## ✨ What You're Testing

Lyva is a fitness app focused on **consistency over perfection**. This is the first internal test version.

### Core Features:

1. **Onboarding (First Launch)**
   - Enter your age, height, weight
   - Set your fitness goal and experience level
   - Configure training days per week

2. **Nutrition Plan**
   - AI generates personalized calorie targets
   - Protein, carbs, and fat recommendations
   - Based on your goals and activity level

3. **Workout Plan**
   - AI generates training program
   - Customized to your equipment and experience
   - Structured exercises with sets/reps

4. **Daily Check-ins**
   - Log weight, waist measurement, steps
   - Track adherence and energy levels
   - Optional notes

5. **Trends**
   - Week-over-week comparisons
   - Visual progress indicators
   - AI coaching suggestions (after 7 days)

---

## 🧪 What to Focus On

### Priority 1: Does it make sense?
- Is the onboarding flow clear?
- Are the AI-generated plans reasonable?
- Is the home screen helpful or confusing?

### Priority 2: Does it work?
- Can you complete a check-in?
- Can you start a workout session?
- Do the trends show correct data?

### Priority 3: Will you use it?
- Would you open this app daily?
- What's missing that you need?
- What's included that you don't care about?

---

## 📝 Testing Checklist

Please try to complete all of these:

**Day 1: Setup**
- [ ] Complete onboarding
- [ ] Generate nutrition plan
- [ ] Generate workout plan
- [ ] Complete first check-in
- [ ] Start a workout session (don't need to finish)

**Day 2-3: Daily Use**
- [ ] Check-in each day
- [ ] Complete one full workout
- [ ] Explore the trends screen

**Day 7+: AI Coaching**
- [ ] Check-in for 7 consecutive days
- [ ] Ask AI coach for plan adjustment (in "My Plan")
- [ ] Review AI suggestions

---

## 🐛 Known Issues (Don't Report These)

These are already on the fix list:
- No way to edit your profile after onboarding
- No settings screen yet
- Can't customize exercises
- No nutrition logging (just plan viewing)
- Trends screen basic (no fancy charts)

---

## 💬 How to Give Feedback

### What We Need to Know:

**Bugs (Something doesn't work):**
- What you were doing
- What you expected to happen
- What actually happened
- Screenshot if possible

**Confusing UX (You were lost or unsure):**
- Where you got stuck
- What you were trying to do
- What was unclear

**Feature Requests (You wish it had X):**
- What you wanted to do
- Why it matters to you
- How you'd use it

### Submit Feedback:
- **Email:** [your email here]
- **Google Form:** [link if you create one]
- **WhatsApp/Telegram:** [if applicable]

---

## ❓ FAQ

**Q: Why do I need to allow "Unknown sources"?**
A: This app isn't on the Google Play Store yet. It's a test version. Once it launches publicly, you'll install it normally.

**Q: Is my data safe?**
A: Yes! All data is stored locally on your phone using Isar (offline-first database). Nothing is sent to external servers except when you use AI features (nutrition/workout plan generation).

**Q: Can I use this long-term?**
A: This is just a test! Features may change or break. Once we launch v1.0, you'll get the stable version.

**Q: The app crashes! What do I do?**
A: Please tell us what you were doing when it crashed. Try deleting and reinstalling the app. If it keeps happening, let us know!

**Q: Can I share this with friends?**
A: Please ask first! We're keeping this to a small group initially. Once it's more stable, we'll expand testing.

**Q: How long will testing last?**
A: About 2 weeks for this version. We'll gather feedback, fix issues, and potentially send v0.1.1 or v0.2.

---

## 🙏 Thank You!

Your feedback helps build a better app. We're looking for:
- **Honest opinions** (be critical!)
- **Real usage** (actually try using it daily)
- **Specific feedback** (not just "it's good" or "it's bad")

This is YOUR chance to shape the product before it launches.

---

## 📱 Technical Details

**Minimum Requirements:**
- Android 5.0 (Lollipop) or higher
- ~50MB free storage
- Internet connection (for AI plan generation only)

**Version:** v0.1.0-beta  
**Release Date:** [Your date]  
**Tester Group:** Internal (5-10 users)

---

## 🚀 Next Steps

After you've tested for a week:
1. We'll send you a feedback form
2. We'll schedule a short call (optional)
3. We'll share v0.1.1 with your suggestions

Thanks for being an early tester! 🎯
