# SKILL.md — chat_commands (CHAT_COMMAND)

## Objective
Handle natural-language chat from the frontend and update `USER.md` + `memory/chat_history.json`.

## Input
```json
{
  "type": "CHAT_COMMAND",
  "message": "Set my weight to 75kg and goal to cut",
  "userSnapshot": { "goal": "", "weight": 70, "tdee": 2200 }
}
```

## Output
Plain-English reply to display in chat. Side effect: updated `USER.md` when applicable.

## Steps
1. Load `USER.md` and `memory/chat_history.json`.
2. Classify intent with Groq (`llama-3.3-70b-versatile`).
3. Execute:
   - **update_profile:** patch weight/goal/budget/height/age → recalc TDEE (cut −500, bulk +300) → write USER.md
   - **show_workout:** parse day name → return exercises from Weekly Plan
   - **calories_today:** read progress log / snapshot
   - **generate_meal_plan:** high-protein meals → update Weekly Plan meals section
   - **generate_workout:** PPL or upper/lower → update Weekly Plan workouts section
4. Append user + assistant messages to `memory/chat_history.json`.
5. Return friendly confirmation (SOUL.md tone).

## Tools
- `read`, `write` (USER.md, chat_history.json)
- Groq API for NL understanding when regex insufficient

## Examples
**User:** "Update my weight to 72kg"  
**AI:** "✅ Updated your weight to 72kg. Your daily calorie target is now 2100 kcal."

**User:** "Generate a high-protein meal plan for today"  
**AI:** Lists meals with macros, updates USER.md Weekly Plan.
