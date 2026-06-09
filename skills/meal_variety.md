# Meal Variety Skill

## Purpose
Avoid repetitive meals; score and rotate suggestions based on recent history, favourites, and bans.

## User fields
- `mealVariety`: rotate | favourites_first | adventurous
- `recentMeals`: last 30 meals logged
- `bannedMeals`: user-banned meal names
- `favouriteMeals`: boost score in favourites_first mode

## Chat commands
- "Swap my lunch" → replace Lunch with new allergy-safe option
- "Something different for dinner" → shuffle daily plan
- "Ban chicken rice bowl" → add to bannedMeals

## UI
Meals tab: Swap meal + Shuffle all buttons.

## Scoring
- Recent meal: -50
- Not in recent: +25
- In favourites: +30
- Allergy conflict: excluded entirely
