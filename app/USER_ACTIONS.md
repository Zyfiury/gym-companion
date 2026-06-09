# What you need to do (Omar)

Everything below requires **your accounts, keys, or legal hosting**. The app code is ready — these steps unlock production.

---

## Critical before App Store / Play Store (do first)

### 1. Firebase Console — Google & Apple login
**Where:** https://console.firebase.google.com → project `gym-b541e`

| Step | Action |
|------|--------|
| 1 | Authentication → Sign-in method → Enable **Email/Password**, **Google**, **Apple** |
| 2 | Project settings → Your apps → Android → Add **SHA-1** fingerprint (see below) |
| 3 | Re-download `google-services.json` → replace `android/app/google-services.json` |
| 4 | Register **iOS app** (bundle ID `com.gymcompanion.gymCompanion`) |
| 5 | Download `GoogleService-Info.plist` → place in `ios/Runner/` |
| 6 | Copy iOS App ID into `.env` → `FIREBASE_IOS_APP_ID=1:928816456435:ios:XXXX` |
| 7 | Firestore → Create database (production mode, your region) |

**Android SHA-1 (run in PowerShell):**
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```
Add the SHA-1 line to Firebase. Repeat with your **release keystore** before Play Store submit.

**Guide:** `GOOGLE_SIGNIN_SETUP.md`

---

### 2. RevenueCat — fix subscription key
**Where:** https://app.revenuecat.com

Your `.env` has `REVENUECAT_KEY=sk_...` — that is a **secret server key**, not for the mobile app.

| Step | Action |
|------|--------|
| 1 | RevenueCat → Project → API keys → copy **Public** Android key (`goog_...`) |
| 2 | Replace in `.env`: `REVENUECAT_KEY=goog_xxxxxxxx` |
| 3 | Create entitlement named **`pro`** |
| 4 | Create offering with **monthly** and **annual** packages |
| 5 | Link Google Play + App Store products (after store setup) |

---

### 3. Legal pages (required by stores)
Host these URLs (can be Notion, GitHub Pages, or your domain):

| Page | URL to use in app |
|------|-------------------|
| Privacy Policy | `https://gymcompanion.app/privacy` |
| Terms of Service | `https://gymcompanion.app/terms` |

Update `lib/config/app_config.dart` if you use different URLs.

Must mention: data collected (email, health, food logs), Firebase, Groq AI, RevenueCat, subscription auto-renewal.

---

### 4. Android release signing
**Where:** your machine + Google Play Console

```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Store the keystore safely. Configure `android/key.properties` and `build.gradle.kts` (see Flutter [signing docs](https://docs.flutter.dev/deployment/android#signing-the-app)).

---

### 5. Apple Developer + App Store Connect
**Where:** https://developer.apple.com ($99/year)

| Step | Action |
|------|--------|
| 1 | Enroll in Apple Developer Program |
| 2 | Identifiers → App ID `com.gymcompanion.gymCompanion` → enable **Sign in with Apple** |
| 3 | Xcode → open `ios/Runner.xcworkspace` → Signing & Capabilities → select your team |
| 4 | App Store Connect → create app listing |
| 5 | Create subscription product matching RevenueCat |

---

### 6. Google Play Console
**Where:** https://play.google.com/console ($25 one-time)

| Step | Action |
|------|--------|
| 1 | Create app → complete Data safety form |
| 2 | Upload AAB: `flutter build appbundle --release` |
| 3 | Create subscription matching RevenueCat |
| 4 | Add privacy policy URL |
| 5 | Internal testing → closed → production |

---

## Important but not blocking local testing

### 7. Rotate exposed API keys
Keys in `.env` are bundled inside the APK. For production:

- Move secrets to CI `--dart-define` or remote config
- Rotate: Groq, Supabase anon (if abused), YouTube, Firebase (if leaked)

### 8. Firebase Email/Password for real users
Console → Authentication → enable Email/Password (if not already).

### 9. Google Places API (delivery restaurant search)
**Where:** Google Cloud Console → same project as YouTube key

| Step | Action |
|------|--------|
| 1 | Enable **Places API** + **Geocoding API** |
| 2 | Add to `.env`: `GOOGLE_PLACES_API_KEY=your-key` (or reuse `YOUTUBE_API_KEY` if same key) |
| 3 | On emulator: Extended Controls → Location → set your city coords |

---

### 10. Custom app icon
Replace default Flutter icon:
- Design 1024×1024 PNG
- Use https://icon.kitchen or `flutter_launcher_icons` package
- Or send me an icon file and I can wire it up

### 11. Store screenshots & copy
Prepare for listings:
- 6–8 phone screenshots (Home, Coach, Workout, Meals, Progress)
- Short description + keywords
- Feature graphic (Play Store): 1024×500

---

## Optional enhancements

| Item | You do | I already did in code |
|------|--------|----------------------|
| YouTube exercise videos | Key is in `.env` ✓ | Integration ready |
| OpenClaw agent gateway | Set `OPENCLAW_GATEWAY_TOKEN` + deploy gateway | Client ready |
| Real domain `gymcompanion.app` | Buy domain + host privacy/terms | Links in app |
| Push notifications prod | Firebase Cloud Messaging server key | FCM wired |
| Physical device testing | Test Google login + purchases on real phone | — |

---

## What I already did (no action needed)

- Full app: AI coach, meals, workouts, barcode, feed, allergies, export
- Google + Apple sign-in code
- Forgot password + delete account
- Home dashboard, premium paywall, Pro gating
- 10 unit tests + 9 Maestro E2E flows
- `scripts/run_all_tests.ps1` one-command QA
- Crashlytics (release builds)
- Analytics event hooks
- Onboarding welcome screen
- Branded in-app splash

---

## Quick test (you, right now)

```powershell
# Terminal 1 — emulator
flutter emulators --launch Pixel_7_API_33

# Terminal 2 — run app
cd c:\Users\omarz\.openclaw\workspace\gymapp\app
flutter run

### 8. Google Cloud Vision (camera calorie scan)
**Where:** https://console.cloud.google.com → project `gym-b541e`

| Step | Action |
|------|--------|
| 1 | APIs & Services → Enable **Cloud Vision API** |
| 2 | Credentials → Create API key → restrict to Vision API |
| 3 | Add to `app/.env`: `GOOGLE_VISION_API_KEY=your_key` |

Without this key, the app falls back to Groq estimates from mock food labels.

---

# Full automated QA
cd c:\Users\omarz\.openclaw\workspace\gymapp
.\scripts\run_all_tests.ps1
```

---

## Priority order (recommended)

1. Firebase SHA-1 + Google auth (15 min) → Google login works  
2. RevenueCat public key (10 min) → real paywall  
3. Privacy + Terms hosted (1 hr) → store requirement  
4. Android keystore + Play upload (1 hr)  
5. Apple Developer + iOS plist (1 hr)  
6. Screenshots + submit (half day)

**Estimated time to live on Play Store:** 1–2 days if you focus on items 1–4.  
**iOS:** add 1 day for Apple review.
