# SKILL.md — personalised_insights

## Objective
Generate personalised coaching insights from weekly progress, food log, and chat history.

## Schedule
- **Every Monday:** PlanAgent or ChatAgent sends automatic insight message.
- **On demand:** User asks "What insights do you have for me?"

## Data sources
1. `/memory/users/{userId}/USER.md` — Food Log, Weekly progress log, Gamification streak
2. `/memory/users/{userId}/chat_history.json` — recent conversation patterns
3. Health metrics (steps, sleep, heart rate) if connected
4. All CHAT_COMMAND payloads include `userId` for routing

## Analysis patterns
- Friday calorie spikes vs weekly average
- Training volume vs recovery (sleep/steps)
- Weight trend vs goal (cut/bulk)
- Streak maintenance and macro adherence

## Steps
1. Load USER.md and chat_history.json.
2. Run local pattern detection (Friday overeating, plateau, etc.).
3. Send context to Groq (`llama-3.3-70b-versatile`) for natural-language insight.
4. Append insight to chat as assistant message.
5. Store in `USER.md` under recent insights if applicable.

## Output example
"📊 Weekly insight: You tend to overeat on Fridays — try a protein-rich snack before dinner. Your 5-day streak is solid — keep it up!"

## Tools
- `read` (USER.md, chat_history.json)
- `write` (chat_history.json)
- Groq API
