# Play Store Release Checklist

Complete these steps in order before submitting to Google Play.

## 1. Firebase (`gym-b541e`)

1. Replace placeholder [`app/android/app/google-services.json`](app/android/app/google-services.json) with the real file from Firebase Console.
2. Enable **Email/Password** and **Google** sign-in under Authentication.
3. Create **Firestore** database (production mode, EU region recommended).
4. Deploy security rules:
   ```bash
   firebase deploy --only firestore:rules
   ```
   Rules file: [`firestore.rules`](firestore.rules)
5. Add Android **release** SHA-1 fingerprint to Firebase (from your upload keystore).
6. Copy credentials into production `app/.env` (never commit):
   - `FIREBASE_PROJECT_ID`, `FIREBASE_API_KEY`, `FIREBASE_ANDROID_APP_ID`, etc.

**Get release SHA-1:**
```powershell
keytool -list -v -keystore upload-keystore.jks -alias upload
```

## 2. API keys (Google Cloud `gym-b541e`)

| Variable | Purpose |
|----------|---------|
| `GROQ_API_KEY` | AI coach, meal pricing |
| `GOOGLE_VISION_API_KEY` | Camera food recognition |
| `GOOGLE_PLACES_API_KEY` | Supermarket / delivery search |
| `YOUTUBE_API_KEY` | Exercise & recipe videos |

Restrict each key to its API in Cloud Console.

## 3. RevenueCat + Play Billing

1. Use **public** Android key: `REVENUECAT_KEY=goog_...` (not `sk_` secret).
2. Create entitlement **`pro`** with monthly + annual packages.
3. Create matching subscription products in Play Console.
4. Link products in RevenueCat dashboard.
5. Test with a license tester account on internal track.

## 4. Release keystore

```powershell
cd app/android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
copy key.properties.example key.properties
# Edit key.properties with your passwords and storeFile path
```

**Back up `upload-keystore.jks` securely.** Losing it prevents future updates.

## 5. Legal pages (GitHub Pages)

1. Push `docs/` to GitHub.
2. Enable Pages: repo Settings → Pages → Source: GitHub Actions.
3. After deploy, verify:
   - `https://<your-username>.github.io/gymapp/legal/privacy.html`
   - `https://<your-username>.github.io/gymapp/legal/terms.html`
4. Update URLs in [`app/lib/config/app_config.dart`](app/lib/config/app_config.dart) if your GitHub username differs from `omarz`.

## 6. Build release AAB

```powershell
cd gymapp
.\scripts\build_release.ps1
```

Output: `app/build/app/outputs/bundle/release/app-release.aab`

## 7. Google Play Console

1. Create app listing (screenshots, feature graphic 1024×500, descriptions).
2. Complete **Data safety** form (email, health, location, photos).
3. Upload AAB to **Internal testing**.
4. Add privacy policy URL from step 5.
5. Promote: Internal → Closed → Production.

## 8. Physical device smoke test

| Feature | Verify |
|---------|--------|
| Email sign-up / login | Firebase |
| Google sign-in | SHA-1 + google-services.json |
| AI coach | Groq key |
| Pro purchase + restore | RevenueCat + Play products |
| Camera calories | Vision API key |
| Meal plan + store | Places API + location |
| Steps on Home | Health Connect permission |
| Delete account | Profile → Delete account |

## Pre-flight (automated)

`build_release.ps1` checks:
- Firebase configured in `.env`
- No `DEV_PRO_OVERRIDE=true` in release `.env`
- `flutter test` passes
