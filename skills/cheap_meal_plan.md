# SKILL.md - cheap_meal_plan

## Objective
Generate duration-based meal plans using the cheapest nearby supermarket (within 5 miles), with UK price estimates via Groq.

## Input
- User location (GPS via LocationService)
- Plan duration: `1 day`, `1 week`, or `1 month`
- User profile: allergies, dietary preferences, weekly budget, nutrition mode

## Output
- Updates `WeeklyPlan` (day/week) or `MonthlyPlan` in USER.md
- Shopping list JSON: supermarket, totalEstimatedCost, items

## Steps
1. Parse duration from chat: "plan for 1 day/week/month"
2. `PlacesService.findSupermarkets` within 8047m (5 mi)
3. Aggregate meal ingredients from `MealVarietyService`
4. For each store, Groq-estimate basket prices
5. Pick cheapest store within budget; fallback to next store if items unavailable
6. Write plan to USER.md via `UserMdSyncService`

## Environment
- `GOOGLE_PLACES_API_KEY` — supermarket discovery
- `GROQ_API_KEY` — UK price estimates
