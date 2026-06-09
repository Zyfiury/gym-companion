# Gym Companion — Test Report
**Date:** 2026-06-06  
**Device:** Android emulator `emulator-5554` (API 33)  
**Build:** `app-debug.apk`

---

## Summary

| Layer | Result |
|-------|--------|
| `flutter analyze` | ✅ 0 errors (18 info/warnings) |
| `flutter test` | ✅ **10/10 passed** |
| Maestro E2E (Flutter) | ✅ **9/9 passed** |
| APK build | ✅ Success |
| Automation script | ✅ `scripts/run_all_tests.ps1` |

---

## One-command automation

```powershell
# Start emulator first:
flutter emulators --launch Pixel_7_API_33

# Full pipeline (analyze → unit tests → build → install → 9 Maestro flows):
.\scripts\run_all_tests.ps1

# Skip rebuild if APK already installed:
.\scripts\run_all_tests.ps1 -SkipBuild

# Unit tests only:
.\scripts\run_all_tests.ps1 -SkipMaestro
```

---

## Unit tests (10/10 ✅)

| Test file | Tests |
|-----------|-------|
| `backend_config_test.dart` | Backend detection from `.env` |
| `barcode_demo_test.dart` | Demo barcode allergy guard |
| `customization_test.dart` | Allergy block, chat block, meal swap |
| `groq_actions_test.dart` | ACTION tag parsing |
| `widget_test.dart` | App splash load |

---

## Maestro E2E (9/9 ✅)

| Flow | Coverage |
|------|----------|
| `setup.yaml` | App launch smoke |
| `login_flow.yaml` | Test account login |
| `onboarding_flow.yaml` | demo@gym.app onboarding |
| `full_app_flow.yaml` | All tabs + logout |
| `swap_meal_flow.yaml` | Meal swap + shuffle |
| `allergy_block_flow.yaml` | Barcode block + chat block |
| `feed_post_flow.yaml` | Create feed post |
| `profile_export_flow.yaml` | CSV/PDF export buttons |
| `chat_rule_flow.yaml` | Rule-based lunch swap |

---

## Key fixes for automation

1. **Barcode semantics** — `explicitChildNodes`, `onTap`, demo barcodes prioritized over API
2. **Chat safety** — Rule-based allergy/log/swap runs before Groq
3. **RevenueCat dev mode** — Uninitialized store treated as Pro (no paywall in tests)
4. **Feed post semantics** — `feed-post-latest` identifier for Maestro
5. **Maestro scroll** — `scrollUntilVisible` for off-screen results

---

## Test accounts

| Email | Password | Profile |
|-------|----------|---------|
| test@gym.app | test123 | Complete, dairy allergy |
| demo@gym.app | demo123 | Incomplete → onboarding |
| alex@gym.app | alex123 | Complete, bulk |

---

## Optional manual checks (not in CI)

| Feature | Notes |
|---------|-------|
| Firebase Auth (new email) | Enable Email/Password in Firebase Console |
| Groq live responses | Network-dependent; rules handle safety-critical paths |
| Camera barcode scan | Physical device + camera permission |
| RevenueCat purchase | Needs store products configured |
