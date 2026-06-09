# Cursor Handoff — Firebase Finalisation

## Status

| Item | State |
|------|-------|
| `.env` Firebase vars | Project ID + Sender ID set; API key + Android App ID are placeholders |
| `google-services.json` | Placeholder in `android/app/` — **must be replaced** |
| `build.gradle.kts` | `applicationId = com.gymcompanion.gym_companion` + google-services plugin |
| `FIREBASE_SETUP.md` | Step-by-step instructions |
| Supabase + Groq | Live and working without Firebase |

## User action required (5 min)

1. Register Android app in Firebase Console (package `com.gymcompanion.gym_companion`)
2. Download real `google-services.json` → replace `android/app/google-services.json`
3. Paste `FIREBASE_API_KEY` and `FIREBASE_ANDROID_APP_ID` into `.env`
4. Run `flutter pub get && flutter run`

## Paste this in Cursor AI (Cmd+K / Ctrl+K)

```
Finalise Firebase for the Gym Companion Flutter app at gymapp/app.

1. Confirm the user has replaced android/app/google-services.json with the real file from Firebase Console and filled FIREBASE_API_KEY + FIREBASE_ANDROID_APP_ID in .env.
2. Run flutter pub get && flutter run on the Android emulator.
3. Verify Firebase.initializeApp succeeds in main.dart and login uses Firebase Auth (not just Supabase).
4. Test: sign up, log food via chat, scan barcode, feed post, export CSV.
5. Run Maestro flows in gymapp/maestro/flows/ and report pass/fail.
6. If Firebase keys are still placeholders, confirm Supabase fallback works and remind user to complete FIREBASE_SETUP.md.
```
