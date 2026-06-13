# Google Play Store Listing Checklist

## Legal URLs (required)

- Privacy: https://zyfiury.github.io/gym-companion/legal/privacy.html
- Terms: https://zyfiury.github.io/gym-companion/legal/terms.html

---

## Required graphics

**Generated assets** (run `python scripts/generate_store_assets.py`):

| Asset | Path |
|-------|------|
| Feature graphic | `store-listing/feature-graphic-1024x500.png` |
| App icon 512 | `store-listing/icon-512.png` |
| App icon 1024 | `store-listing/icon-1024.png` |
| Screenshot placeholders | `store-listing/screenshots/*-PLACEHOLDER.png` - **replace with real device captures** |

See [`SCREENSHOT_GUIDE.md`](SCREENSHOT_GUIDE.md) for capture instructions.

| Asset | Specification |
|-------|---------------|
| Phone screenshots | 6–8 portrait, min 1080×1920 - Home, Coach, Food, Workout, Progress, Profile, Paywall, Feed |
| Feature graphic | 1024×500 PNG |
| App icon | 512×512 PNG |

---

## Store listing copy (draft)

**App name:** Gym Companion

**Short description (80 chars max):**
```
AI coach, photo food logging, live workout tracking & meal plans in one app
```

**Full description:**
```
One coach for your training and your plate. Gym Companion combines an AI coach, effortless food logging, and live workout tracking - so you don't need three apps to hit one goal.

LOG FOOD IN SECONDS
• Snap a photo of your meal - AI estimates calories, protein, carbs, fat and micros
• Scan any barcode, search verified foods, or log by voice
• Meals grouped by breakfast/lunch/dinner with editable servings
• Verified vs estimated nutrition badges, so you know what's accurate

A COACH THAT ACTUALLY KNOWS YOU
• Mara, your AI coach, sees your meals, workouts, streak and goals
• Ask anything - she answers with your real data, not generic advice
• She can log food, swap meals, and update your plan right from chat
• Morning check-ins adapt your day to how you slept and feel

TRAIN WITH A PLAN
• Weekly workout splits built around your goal, schedule and any limitations
• Live session mode: track sets, reps and weight with rest timers
• Plate calculator, exercise videos, and "last session" history per lift
• Progressive overload targets - know exactly what to lift next time

EAT FOR YOUR GOAL (AND YOUR BUDGET)
• Meal plans matched to your TDEE, allergies and weekly budget
• Shopping lists priced at your local supermarket
• Delivery and eat-out search with macro estimates when life happens

STAY CONSISTENT
• XP, levels, streaks with freezes, achievements and weekly goals
• Personal records with celebrations when you hit a new best
• Weekly recaps and fun facts about your own habits
• Community feed and leaderboard to keep you honest

PRO (optional)
• Unlimited coach messages, premium analytics, exports and leaderboard

Whether you're cutting, bulking or maintaining, Gym Companion adapts to your body, your kitchen and your life.

Not medical advice. Consult a professional before starting any program.
```

---

## Data safety form

**Full step-by-step answers:** [`DATA_SAFETY_FORM.md`](DATA_SAFETY_FORM.md)

Play Console → **App content → Data safety**

| Data type | Collected | Shared with | Purpose | Optional |
|-----------|-----------|-------------|---------|----------|
| Email address | Yes | Firebase | Account management | No |
| Name | Yes | Firebase | Account management | No |
| Health & fitness (weight, height, age, steps, workouts) | Yes | Firebase | App functionality | No |
| Photos | Yes | Google Vision, Groq | Barcode scan, calorie estimation | Yes (camera) |
| Precise location | Yes | Google Places | Store/restaurant search | Yes |
| App interactions | Yes | Firebase Analytics | Analytics | No |
| Crash logs | Yes | Firebase Crashlytics | Diagnostics | No |

Additional answers:
- Data encrypted in transit: **Yes**
- Users can request deletion: **Yes** (Profile → Delete account)
- Data used for advertising: **No**
- Privacy policy URL: `https://zyfiury.github.io/gym-companion/legal/privacy.html`

---

## Upload AAB

**Output path after build:**
```
app/build/app/outputs/bundle/release/app-release.aab
```

**Play Console (recommended):**
1. Play Console → your app → **Testing → Internal testing**
2. **Create new release**
3. Upload `app-release.aab`
4. Add release notes (e.g. "Initial internal test build")
5. **Review release → Start rollout to Internal testing**
6. Copy the **opt-in link** and open on your test device

**Validate AAB locally (optional):**
```powershell
java -jar bundletool.jar validate --bundle="app\build\app\outputs\bundle\release\app-release.aab"
```

---

## Pre-production gate

**Before Production:** complete [`PRE_PRODUCTION_TEST.md`](PRE_PRODUCTION_TEST.md) - especially **purchase flow on a real device** via Internal testing.

---

## Post-upload smoke test

| Feature | How to verify |
|---------|---------------|
| Email sign-up / login | Create account, sign out, sign back in |
| Google sign-in | Use Google button on login screen |
| AI coach | Send a message; check 10 free/day limit |
| Pro purchase + restore | Profile → Upgrade; then Restore purchases |
| Camera calories | Coach → camera icon → scan a meal |
| Barcode scan | Food/Workout → barcode scanner |
| Nearby stores | Food tab with location permission |
| Health Connect steps | Home screen step count |
| Delete account | Profile → Account → Delete account |

---

## Release promotion path

Internal testing → Closed testing (optional) → Open testing (optional) → **Production**

Complete all Play Console checklist items (content rating, target audience, news app declaration, etc.) before production.
