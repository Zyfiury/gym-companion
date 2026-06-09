# SKILL.md - food_recognition

## Objective
Recognise food from a meal photo and estimate calories/macros for automatic food logging.

## Flow
1. User taps camera in Coach chat
2. `image_picker` captures or selects photo
3. `VisionCalorieService.analyze`:
   - Google Cloud Vision API (LABEL_DETECTION + OBJECT_LOCALIZATION)
   - Groq estimates portions and macros
   - `AllergyGuard` blocks unsafe items
4. User confirms in bottom sheet
5. Log to `foodLog` and `dailyMacrosLogged`

## Environment
- `GOOGLE_VISION_API_KEY` — Cloud Vision on project gym-b541e
- `GROQ_API_KEY` — macro estimation fallback

## Low confidence
If confidence < 0.6, prompt user to review/adjust before logging.
