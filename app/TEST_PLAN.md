# Gym Companion — Full Test Plan

## Test layers

| Layer | Tool | Scope |
|-------|------|-------|
| L1 Static | `flutter analyze` | Compile-time issues |
| L2 Unit | `flutter test` | Allergy guard, chat rules, app boot |
| L3 UI E2E | Maestro | Login, tabs, chat, meals, barcode, onboarding |
| L4 Manual | Checklist below | Firebase, Groq, voice, export, paywall |

## Feature matrix

| Feature | Tab/Screen | Maestro flow | Unit test |
|---------|------------|--------------|-----------|
| App launch | Splash | `setup.yaml` | `widget_test.dart` |
| Login (local test account) | Login | `login_flow.yaml` | — |
| Full navigation | All 6 tabs | `full_app_flow.yaml` | — |
| Onboarding wizard | Onboarding | `onboarding_flow.yaml` | — |
| Allergy guard (barcode) | Workout | `allergy_block_flow.yaml` | `customization_test.dart` |
| Allergy guard (chat) | Chat | `allergy_block_flow.yaml` | `customization_test.dart` |
| Meal swap/shuffle | Meals | `swap_meal_flow.yaml` | `customization_test.dart` |
| AI chat (Groq) | Chat | manual / full_app | — |
| Barcode scan (demo) | Workout | `allergy_block_flow.yaml` | — |
| Social feed + post | Feed | full_app (partial) | — |
| Profile preferences | Profile | manual | — |
| Progress / weight | Progress | full_app (nav only) | — |
| Export CSV/PDF | Profile | manual | — |
| Voice input | Chat | manual | — |
| Paywall | Chat | manual | — |
| Firebase auth | Login | manual (needs console setup) | — |
| YouTube videos | Workout | manual (needs API key) | — |

## Maestro Flutter flows (automated)

```bash
cd gymapp/maestro
maestro test flows/setup.yaml
maestro test flows/login_flow.yaml
maestro test flows/full_app_flow.yaml
maestro test flows/onboarding_flow.yaml
maestro test flows/allergy_block_flow.yaml
maestro test flows/swap_meal_flow.yaml
```

## Pre-requisites

- Android emulator running (`emulator-5554`)
- App built: `cd gymapp/app && flutter build apk --debug`
- Login cascade: Firebase → Supabase → local test accounts

## Test accounts

| Email | Password | Profile |
|-------|----------|---------|
| test@gym.app | test123 | Complete, dairy allergy |
| demo@gym.app | demo123 | Incomplete (onboarding) |
| alex@gym.app | alex123 | Complete, bulk goal |
