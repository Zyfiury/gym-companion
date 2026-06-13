# Launch status — v1.0.5+11

## Quality scores (app-focused)

| Area | Score | Notes |
|------|-------|-------|
| Feature breadth | 9 | Full gym + food + coach + gamification |
| Design & polish | 9 | Dark/light onboarding, Profile, system theme default |
| Coach / AI | 8.5 | Groq + live-data fallbacks |
| Technical quality | 9 | 127 tests passing |
| Device polish | 8 | Needs your phone smoke test |
| vs market | 8.5 | Strong unified app; store listing pending |

## Shipped in v1.0.5

- [x] Theme-aware onboarding (dark + light via `ObsidianPalette`)
- [x] Default appearance: **System**
- [x] Profile → Account: **Appearance** toggle + **Manage subscription**
- [x] Themed delete-account dialog
- [x] Web limit banner on Home (photo/barcode/health)
- [x] Personalized notification copy (streak, protein gap, goal)
- [x] Apple Health connect error messages (iOS)
- [x] Coach: richer today’s workout replies

## Your next step (on device)

Run through `docs/PRE_PRODUCTION_TEST.md` on your phone — log food, coach, workout complete, midnight rollover.

```powershell
cd app
flutter run
# or release AAB:
..\scripts\build_release.ps1
```

Web test: https://zyfiury.github.io/gym-companion/ (redeploy with `.\scripts\deploy_web.ps1` for latest)
