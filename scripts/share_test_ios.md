# Send Gym Companion to an iPhone friend

**You cannot send the Android `.apk` to an iPhone** — iOS uses a completely different format (`.ipa`) and Apple does not allow simple “install this file” like Android.

## Best option: TestFlight (recommended)

Your friend installs Apple’s **TestFlight** app, you invite them by email, they tap Install. Builds last 90 days.

### What you need

1. **Apple Developer Program** — [developer.apple.com](https://developer.apple.com) — **£99 / year**
2. A **Mac** (or cloud Mac builder — see below)
3. Your app repo + `app/.env` with API keys

### Steps (with a Mac)

```bash
cd app
flutter pub get
open ios/Runner.xcworkspace
```

In Xcode → **Runner** → **Signing & Capabilities**:
- Team: your Apple Developer team
- Bundle ID: `com.gymcompanion.gym_companion` (must match App Store Connect)

Add `GoogleService-Info.plist` to `ios/Runner/` if using Firebase (download from Firebase Console).

Build archive:
```bash
flutter build ipa --release
```

Upload:
- Xcode → **Product → Archive → Distribute App → TestFlight**
- Or: [Transporter app](https://apps.apple.com/app/transporter/id1450874784) with the `.ipa` from `build/ios/ipa/`

In [App Store Connect](https://appstoreconnect.apple.com):
1. Create app **Gym Companion**
2. Wait for build processing (~10–30 min)
3. **TestFlight** → **Internal Testing** or **External Testing**
4. Add friend’s **Apple ID email** as tester
5. They get an email → open in TestFlight → Install

Test login: `test@gym.app` / `test123`

---

## No Mac? Use Codemagic (cloud build)

1. Sign up at [codemagic.io](https://codemagic.io) and connect your GitHub repo
2. Add Apple certificates + App Store Connect API key in Codemagic
3. Use workflow `codemagic.yaml` in repo root (if present) or Flutter iOS template
4. Build uploads to TestFlight automatically

Free tier has limited build minutes; paid plans for private apps.

---

## Other options (usually worse)

| Method | Pros | Cons |
|--------|------|------|
| **Ad Hoc IPA** | No App Store review | Need friend’s device UDID, max 100 devices, still need £99 dev account + Mac |
| **AltStore / Sideloadly** | No £99 fee | Expires every 7 days, fiddly, not for real testing |
| **App Store public** | Everyone can install | Full review, privacy policy, screenshots |

---

## Quick checklist before iOS build

- [ ] `ALLOW_SIDELOAD_TESTER=true` in `app/.env` (for test accounts on release/profile builds)
- [ ] `GOOGLE_PLACES_API_KEY` set (delivery / eat out)
- [ ] `GROQ_API_KEY` set (AI coach)
- [ ] Firebase iOS app + `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Location / camera / mic usage strings in `ios/Runner/Info.plist` (already added)

---

## What to tell your friend

1. Install **TestFlight** from the App Store
2. Accept your email invite
3. Tap **Install** on Gym Companion
4. Allow **location** when asked (Food → Delivery & eat out)
5. Login: `test@gym.app` / `test123`
