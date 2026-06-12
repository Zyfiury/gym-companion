# Screenshot Capture Guide — Play Store

Play requires **2–8 phone screenshots**, portrait, minimum **1080×1920** (or 1440×2560).

Generated placeholders are in `store-listing/screenshots/` — **replace each with a real capture before upload**.

---

## How to capture on Android

1. Install the app from your **Internal testing** opt-in link
2. Sign in and complete onboarding (or use a populated test account)
3. Navigate to each screen below
4. **Power + Volume Down** to screenshot
5. Transfer to PC or upload directly from device

Optional: Android Studio → **Device Manager → Screenshot** for exact dimensions.

---

## Recommended 8 screenshots

| # | File name | Screen | What to show |
|---|-----------|--------|--------------|
| 1 | `01-home.png` | **Home** | Greeting, macro ring with calories logged, streak/XP |
| 2 | `02-coach.png` | **Coach** | AI conversation with a helpful reply |
| 3 | `03-food.png` | **Food** | Today's meals with macros |
| 4 | `04-workout.png` | **Workout** | Weekly split with exercises |
| 5 | `05-progress.png` | **Progress** | Weight chart or PR list |
| 6 | `06-profile.png` | **Profile → You** | Avatar, goal badge, stats |
| 7 | `07-paywall.png` | **Pro paywall** | Monthly/annual plans (shows subscriptions work) |
| 8 | `08-feed.png` | **Feed** | Community posts or leaderboard |

Save final files to: `store-listing/screenshots/` (remove `-PLACEHOLDER` from names).

---

## Tips for good store screenshots

- Use **light or dark mode consistently** across all shots (dark matches brand)
- Ensure **no debug banners** or "0 msgs left" unless showing paywall intentionally
- Crop out status bar personal info if desired (not required)
- First screenshot is most important — use **Home** or **Coach**
- Avoid empty states; log food / complete profile first

---

## Upload in Play Console

**Grow → Store presence → Main store listing → Phone screenshots**

Drag images in order (Home first). Add tablet screenshots only if you support tablets.

---

## Other graphics

| Asset | Location | Size |
|-------|----------|------|
| Feature graphic | `store-listing/feature-graphic-1024x500.png` | 1024×500 |
| App icon | `store-listing/icon-512.png` | 512×512 |
| High-res icon (if asked) | `store-listing/icon-1024.png` | 1024×1024 |

Regenerate graphics:
```powershell
python scripts/generate_store_assets.py
```
