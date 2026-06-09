# SKILL.md - plan_generation

## Objective
Generate a personalized weekly workout split and daily macro targets based on user's goals, stats, and dietary preferences.

## Input
- User data from `USER.md` (goal, weight, height, age, TDEE, dietary restrictions)

## Output
- Weekly workout plan (detailed exercises, sets, reps, structured markdown)
- Daily macro targets (calories, protein, carbs, fats, structured markdown)

## Steps
1. Read user data from `USER.md`.
2. Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation:
   - For men: `BMR = (10 * weight in kg) + (6.25 * height in cm) - (5 * age in years) + 5`
   - For women: `BMR = (10 * weight in kg) + (6.25 * height in cm) - (5 * age in years) - 161`
3. Calculate Total Daily Energy Expenditure (TDEE) by multiplying BMR by an activity factor (assume moderate: 1.55 if not specified by user).
4. Determine caloric target based on user's goal:
   - `Cut`: `TDEE - 500 kcal`
   - `Bulk`: `TDEE + 300 kcal`
   - `Maintain`: `TDEE`
5. Distribute macros (protein, carbs, fats) based on caloric target and goal:
   - `Protein`: ~1.8-2.2g/kg bodyweight (adjust based on goal).
   - `Fats`: ~0.8-1g/kg bodyweight.
   - `Carbohydrates`: Remaining calories after protein and fat allocation.
6. Generate a 7-day workout split (e.g., Push/Pull/Legs, Upper/Lower, Full Body). For each day, specify focus and a list of exercises with sets and reps.
7. Generate a daily meal plan outline (e.g., Breakfast, Lunch, Dinner, Snack) with general descriptions to meet macro targets.
8. Store the calculated macros and generated workout/meal plans in `USER.md` under the "Generated Plan" section, formatted as structured Markdown.

## Tools to Use
- `read` (to access USER.md)
- `write` (to store the generated plan in USER.md)
- Internal calculation logic (for BMR, TDEE, macros)

## Important Considerations
- Adhere to the SOUL.md tone: motivating but not pushy, honest, beginner-friendly.
- Prioritize user safety and sustainable progress over extreme measures.
- Ensure workout plans emphasize progressive overload.
- Dynamic adjustment of activity factor/macro distribution based on user feedback/progress (future enhancement).
