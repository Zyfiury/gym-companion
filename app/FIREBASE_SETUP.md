# Firebase Setup — Gym Companion (Flutter)

Project: **gym-b541e**  
Sender ID: **928816456435**  
Android package: **com.gymcompanion.gym_companion**

---

## Step 1 — Register the Android app in Firebase

1. Go to [Firebase Console](https://console.firebase.google.com) and open project **gym-b541e**.
2. Click the **Android** icon (or **Add app** → **Android**).
3. Enter Android package name: `com.gymcompanion.gym_companion`
   - This must match `applicationId` in `android/app/build.gradle.kts`.
4. App nickname (optional): `Gym Companion`
5. Click **Register app**.

---

## Step 2 — Download and replace `google-services.json`

1. On the next screen, click **Download google-services.json**.
2. Replace the placeholder file at:

   ```
   gymapp/app/android/app/google-services.json
   ```

   Overwrite the entire file — do not edit the placeholder manually.

See also: `android/app/google-services.README.md`

---

## Step 3 — Copy keys into `.env`

Open `gymapp/app/.env` and fill in:

| Variable | Where to find it |
|----------|------------------|
| `FIREBASE_API_KEY` | Firebase Console → ⚙️ Project settings → General → **Web API Key** (starts with `AIza...`) |
| `FIREBASE_ANDROID_APP_ID` | Project settings → Your apps → Android app → **App ID** (`1:928816456435:android:...`) |

Already set (do not change):

```env
FIREBASE_PROJECT_ID=gym-b541e
FIREBASE_MESSAGING_SENDER_ID=928816456435
```

Example after filling in:

```env
FIREBASE_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
FIREBASE_ANDROID_APP_ID=1:928816456435:android:abcdef123456
```

---

## Step 4 — Run the app

```bash
cd gymapp/app
flutter pub get
flutter run
```

Firebase Auth, Firestore, and push notifications activate when `FIREBASE_API_KEY` and `FIREBASE_ANDROID_APP_ID` are valid (not placeholders).

Until then, the app uses **Supabase** (already configured in `.env`) as the cloud backend.

---

## Optional — Automate with FlutterFire CLI

```bash
firebase login
flutterfire configure --project=gym-b541e
```

This downloads `google-services.json`, generates `lib/firebase_options.dart`, and can populate `.env` automatically.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `google-services.json is missing` | Download from Firebase after registering Android app |
| `No Firebase App` on startup | Check `.env` has real `FIREBASE_API_KEY` and `FIREBASE_ANDROID_APP_ID` |
| Package name mismatch | Firebase app package must be `com.gymcompanion.gym_companion` |
| Build fails after adding plugin | Ensure `google-services.json` is valid JSON (replace placeholder entirely) |
