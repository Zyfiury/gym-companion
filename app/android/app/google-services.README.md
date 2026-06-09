# google-services.json — PLACEHOLDER

The file `google-services.json` in this folder is a **placeholder**.

## Replace it with the real file

1. Open [Firebase Console](https://console.firebase.google.com) → project **gym-b541e**
2. Click **Add app** → **Android**
3. Package name: `com.gymcompanion.gym_companion`
4. Click **Register app**
5. **Download google-services.json**
6. **Replace** `android/app/google-services.json` with the downloaded file (do not merge — overwrite entirely)
7. Copy values into `gymapp/app/.env`:
   - `FIREBASE_API_KEY` = Web API Key from Project settings
   - `FIREBASE_ANDROID_APP_ID` = App ID from the Android app (format `1:928816456435:android:...`)

Then run:

```bash
flutter pub get
flutter run
```
