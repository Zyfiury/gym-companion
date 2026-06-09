# SKILL.md - progress_checkin

## Objective
Track user's progress (weight, measurements, workout PRs), provide macro check-in functionality, and suggest plan adjustments if a plateau is detected.

## Input
- **For Macro Check-in (8pm daily cron):** User's logged food intake for the day (free text).
- **For Progress Tracking (weekly, e.g., after PlanAgent rerun):** User's latest `weight`, `measurements`, `workout_PRs` (from `USER.md`).
- Current `daily_macro_targets` and `weekly_workout_plan` (from `USER.md`).

## Output
- **For Macro Check-in:** Updated `USER.md` with logged food and macro adherence feedback. Message to user.
- **For Progress Tracking:** Updated `USER.md` with progress analysis. Recommendations for `PlanAgent` adjustments. Message to user.

## Steps (Macro Check-in - triggered by 8pm daily cron)
1. Receive user's free-text `food_log` for the day.
2. **(Future: Barcode Scanner/Food Database Agent):** Estimate macros from the `food_log`.
3. Compare `estimated_macros` against `daily_macro_targets` from `USER.md`.
4. Generate gentle, motivating feedback (adhering to `SOUL.md` tone).
5. Append the `food_log`, `estimated_macros`, and `feedback` to `USER.md`'s "Weekly Progress Log" section.
6. Send the feedback message to the user (via Discord DM).

## Steps (Progress Tracking - triggered by weekly PlanAgent rerun)
1. Read user's `weight`, `height`, `age`, `goal` from `USER.md`.
2. Access historical `Weekly Progress Log` from `USER.md` (e.g., past weights, measurements).
3. Analyze trends to detect plateaus (e.g., no weight change for 2-3 weeks on a `cut` goal).
4. If a plateau is detected:
   - Recommend adjustments (e.g., slight caloric deficit increase, minor workout volume change) to `PlanAgent` (as an internal message or by directly updating `USER.md` for `PlanAgent` to pick up).
   - Generate encouraging advice for the user.
5. Log the analysis and recommendations in `USER.md`.
6. Send the advice message to the user.

## Tools to Use
- `read` (to access USER.md)
- `write` (to update USER.md)
- Internal analysis logic (for macro estimation, plateau detection, trend analysis)
- `sessions_send` (to send messages to the user via Discord DM)

## Important Considerations
- **Macro Estimation:** Accuracy is key for effective feedback. Requires robust food database integration.
- **Plateau Definition:** Clear, customizable criteria for detecting plateaus.
- **Feedback Tone:** Always positive, motivating, and non-judgmental.
- **Privacy:** Secure handling of sensitive user progress data.
