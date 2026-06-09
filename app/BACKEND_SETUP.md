# Backend Setup Guide

## 1. Environment variables

Copy `.env.example` to `.env` in `gymapp/app/`:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GROQ_API_KEY=gsk_your_key
REVENUECAT_KEY=your_revenuecat_key
```

**Without keys:** app falls back to local SharedPreferences + rule-based chat (existing behaviour).

## 2. Supabase

1. Create project at [supabase.com](https://supabase.com)
2. Run SQL from `gymapp/supabase/schema.sql` in the SQL editor
3. Enable Email auth in Authentication → Providers
4. Paste URL + anon key into `.env`

## 3. Groq AI

1. Get free API key at [console.groq.com](https://console.groq.com)
2. Add `GROQ_API_KEY=gsk_...` to `.env`
3. Chat tab uses `llama-3.3-70b-versatile` with action tags for food logging

## 4. RevenueCat (optional)

1. Create app at [revenuecat.com](https://revenuecat.com)
2. Create `pro` entitlement + monthly product
3. Add `REVENUECAT_KEY` to `.env`
4. Without key: all features free (dev mode)

## 5. Firebase push notifications (optional)

Local streak reminders (8pm daily) work without Firebase.

For remote push via FCM:

1. Create project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android + iOS apps
3. Copy config values into `.env`:
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_API_KEY`
   - `FIREBASE_APP_ID`
   - `FIREBASE_MESSAGING_SENDER_ID`
   - `FIREBASE_IOS_BUNDLE_ID` (iOS only)
4. (Recommended) Download `google-services.json` → `android/app/`
5. (Recommended) Download `GoogleService-Info.plist` → `ios/Runner/`

## 6. iOS release checklist

Permissions are in `ios/Runner/Info.plist`:

- Camera (barcode scanner)
- Microphone + Speech (voice chat)
- Health (steps)
- Background modes (push)

Enable **HealthKit** capability in Xcode before App Store submission.

## 7. Android notes

- `minSdk = 26` (required by health plugin)
- Permissions: camera, mic, activity recognition, notifications, health steps

## 8. Run

```bash
cd gymapp/app
flutter pub get
flutter run
```

## Architecture

| Layer | File |
|-------|------|
| Config | `lib/services/backend_config.dart` |
| Supabase | `lib/services/supabase_service.dart` |
| Groq AI | `lib/services/groq_chat_service.dart` |
| Open Food Facts | `lib/services/food_api_service.dart` |
| Health | `lib/services/health_service.dart` |
| Export | `lib/services/export_service.dart` |
| Subscriptions | `lib/services/subscription_service.dart` |
| Weekly plans | `lib/services/plan_agent_service.dart` |
| Notifications | `lib/services/notification_service.dart` |
| Firebase options | `lib/firebase_options.dart` |

`AppState` auto-detects Supabase/Groq and uses hybrid local+cloud storage. Feed updates in real time when Supabase is connected.
