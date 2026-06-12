# Play Store screenshots

## Automated capture (recommended)

1. Start an Android emulator or connect a phone with USB debugging.
2. Run:

```powershell
cd C:\Users\omarz\.openclaw\workspace\gymapp
.\scripts\capture_screenshots.ps1
```

3. Pick **6–8 PNGs** from the timestamped folder under `docs/screenshots/`.

## Recommended set for Play Console (upload in this order)

| # | Maestro file | Screen | Why |
|---|--------------|--------|-----|
| 1 | `02_home.png` | Home dashboard | First impression — macros ring |
| 2 | `03_coach_chat.png` | AI Coach | Core differentiator |
| 3 | `07_meals_day.png` | Food / meals | Nutrition value |
| 4 | `04_workout_barcode.png` | Workout | Training features |
| 5 | `10_progress.png` | Progress | Charts & tracking |
| 6 | `12_profile.png` | Profile | Personalisation |
| 7 | `13_paywall.png` | Pro paywall | Shows subscription (optional) |
| 8 | `11_feed.png` | Community feed | Social proof (optional) |

## Play Console requirements

- **Format:** PNG or JPEG
- **Size:** 1080×1920 minimum (portrait phone)
- **Max:** 8 screenshots per device type
- Crop status bar if needed; avoid personal data in shots (use test account)

## Manual capture on a real device

Power + Volume Down on most Android phones while running the internal-test build.
