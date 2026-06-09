# Google & Apple Sign-In Setup

## 1. Firebase Authentication

1. Open [Firebase Console](https://console.firebase.google.com) → project **gym-b541e**
2. **Authentication** → **Sign-in method**
3. Enable:
   - **Email/Password**
   - **Google** — set support email
   - **Apple** (for iOS)

## 2. Android — Google Sign-In

### SHA-1 fingerprints

```powershell
# Debug keystore (for development)
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# Release keystore (create first — see LAUNCH_PLAN.md)
keytool -list -v -keystore upload-keystore.jks -alias upload
```

Add **both** SHA-1 values in Firebase → Project settings → Your apps → Android app → Add fingerprint.

### google-services.json

After adding SHA-1, re-download `google-services.json`. It should contain `oauth_client` entries (currently empty).

Replace: `android/app/google-services.json`

## 3. iOS — Google + Apple

### Register iOS app in Firebase

- Bundle ID: `com.gymcompanion.gymCompanion` (must match Xcode)
- Download `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info.plist`

### Xcode capabilities

1. Open `ios/Runner.xcworkspace`
2. Runner target → **Signing & Capabilities**
3. Add **Sign in with Apple**
4. Add **Push Notifications** (already have background modes)

### Info.plist — Google URL scheme

Add reversed client ID from `GoogleService-Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

### .env

```
FIREBASE_IOS_APP_ID=1:XXXX:ios:XXXX
FIREBASE_IOS_BUNDLE_ID=com.gymcompanion.gymCompanion
```

## 4. Apple Developer

1. [developer.apple.com](https://developer.apple.com) → Identifiers → your App ID
2. Enable **Sign in with Apple**
3. Firebase → Apple provider → paste Service ID + key if using web flow

## 5. Test

```powershell
flutter run --release
# Tap "Continue with Google" on login screen
# On iOS also test "Continue with Apple"
```

## Troubleshooting

| Error | Fix |
|-------|-----|
| `CONFIGURATION_NOT_FOUND` | Enable Email/Password in Firebase Auth |
| Google sign-in cancelled | Normal — user dismissed picker |
| `10:` / DEVELOPER_ERROR (Android) | Wrong SHA-1 or outdated `google-services.json` |
| Apple sign-in fails on simulator | Use real device; simulator needs iOS 13+ signed into iCloud |
