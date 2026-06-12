# Pre-Production Testing Checklist

**Do not submit to Production until every item below passes on a real Android device using your Internal testing build.**

Install via Play Console internal test opt-in link (not sideload APK) so billing matches production.

---

## 1. Purchase flow (critical)

| Step | Expected result | Pass |
|------|-----------------|------|
| Open app from Play internal test link | Latest store build installs | ☐ |
| Sign in with your test Google account (license tester) | Login works | ☐ |
| Profile → Account → **Upgrade to Pro** | Paywall shows monthly + annual prices | ☐ |
| Complete **monthly** purchase | Google Play sheet appears; purchase succeeds | ☐ |
| App shows Pro features (unlimited coach, export, etc.) | `isPro` active | ☐ |
| RevenueCat dashboard → Customers | `pro` entitlement active for your user | ☐ |
| Uninstall → reinstall → **Restore purchases** | Pro restored | ☐ |
| Cancel test subscription in Play → Subscriptions | Cancellation works | ☐ |

**License tester setup:** Play Console → **Testing → License testers** → add your Gmail.

---

## 2. Core app smoke test

| Feature | Pass |
|---------|------|
| Email sign-up / sign-in | ☐ |
| Google sign-in | ☐ |
| Onboarding → complete profile | ☐ |
| Home — macro ring updates after logging food | ☐ |
| Coach — AI reply (Groq) | ☐ |
| Coach — "lose 10kg" does NOT set weight to 10kg | ☐ |
| Food — swap meal | ☐ |
| Workout — view today's plan | ☐ |
| Progress — log weight | ☐ |
| Barcode scan | ☐ |
| Camera meal scan (Vision API) | ☐ |
| Nearby stores / delivery (Places + location) | ☐ |
| Health Connect steps on Home | ☐ |
| Feed — create post | ☐ |
| Profile — change avatar photo | ☐ |
| Profile → Delete account | ☐ |

---

## 3. Store listing verification

| Item | Pass |
|------|------|
| Privacy policy URL loads | ☐ |
| Terms URL loads | ☐ |
| Screenshots are **real** device captures (not placeholders) | ☐ |
| Feature graphic uploaded (1024×500) | ☐ |
| Data safety form submitted and matches privacy policy | ☐ |
| Content rating questionnaire complete | ☐ |
| Target audience / news app declarations complete | ☐ |

---

## 4. Production gate

Only promote to **Production** when:

1. All purchase flow steps pass on a physical device
2. RevenueCat shows live `pro` entitlements from Play (not Test Store only)
3. No crash on cold start / login / paywall
4. Data safety and legal URLs are live
5. You have tested on at least one non-developer device if possible

---

## Quick commands

```powershell
# Rebuild AAB if needed
cd C:\Users\omarz\.openclaw\workspace\gymapp\app
flutter build appbundle --release

# Regenerate store graphics
cd C:\Users\omarz\.openclaw\workspace\gymapp
python scripts/generate_store_assets.py
```

AAB path: `app\build\app\outputs\bundle\release\app-release.aab`
