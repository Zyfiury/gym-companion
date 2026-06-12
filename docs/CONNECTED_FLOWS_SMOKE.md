# Connected Flows — Manual & E2E Smoke Checklist

Use after deploying Firestore rules/indexes and a new internal build.

## Deploy backend (once per release)

```powershell
cd gymapp
firebase deploy --only firestore:rules,firestore:indexes --project gym-b541e
```

## Build app

```powershell
cd app
flutter test
flutter build apk --debug
# or release: ..\scripts\build_release.ps1
```

## Maestro (device/emulator)

Core suite (12 flows, ~5 min on Pixel 9 API 33 emulator):

```powershell
cd maestro
maestro test flows/connected_flows_smoke.yaml flows/feed_post_flow.yaml flows/login_flow.yaml flows/release_smoke.yaml flows/allergy_block_flow.yaml flows/log_meal_flow.yaml flows/swap_meal_flow.yaml flows/chat_rule_flow.yaml flows/chat_workout_flow.yaml flows/custom_workout_flow.yaml flows/profile_export_flow.yaml flows/cheap_meal_plan_flow.yaml
```

Last run: **12/12 passed** (includes connected flows + barcode allergy warning flow).

## Manual checks

| Flow | Steps | Expected |
|------|--------|----------|
| Steps → burn | Connect Health Connect, walk/sync steps | Home shows step kcal subtext; burned included in net |
| Food log | Log food from Meals or barcode | Ring pulses; eaten count updates |
| Barcode allergy | Scan demo yogurt `5000112588103` with dairy allergy | Red banner; must tap **Log anyway** |
| Workout complete | Home → Today's session → Mark as Complete | Status badge Completed; +25 XP; session in Firestore |
| Workout skip | Skip today with reason | Status Skipped; no XP |
| Weight → TDEE | Progress → log weight ±5 kg | Banner if target shifts >50 kcal |
| PR | Complete workout with new best weight | Celebration modal; Share to Feed |
| Feed XP | General post | +5 XP |
| Feed linked | Post with linked meal/workout/PR | +10 XP; Firestore validates activityId |
| Coach context | Ask coach "how am I doing today?" | Response references today's eaten/burned/workout |

## Test account

Use **Fill test account** on login (`user_test_001` / local auth) for Maestro flows.

## Firestore collections touched

- `users/{uid}/daily_logs/{date}` — burn totals, workout status
- `users/{uid}/food_entries/{id}` — feed meal links
- `users/{uid}/workout_sessions/{id}` — feed workout links
- `users/{uid}/personal_records/{id}` — PR links
- `feed_posts/{id}` — typed posts with optional `activityId`
