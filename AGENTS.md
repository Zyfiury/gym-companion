## AGENTS.md - Agent Architecture for Gym App

### PlanAgent
- **Role:** Persistent agent.
- **Schedule:** Runs every Sunday.
- **Function:** Generates weekly workout split and daily macro targets from `USER.md`.

### LocationAgent
- **Role:** Ephemeral agent.
- **Function:** Handles GPS and store/restaurant API calls (Google Places, Trolley API).

### RecipeAgent
- **Role:** Ephemeral agent.
- **Function:** Generates recipes from ingredients + macros, fetches YouTube video via YouTube Data API.

### DeliveryAgent
- **Role:** Ephemeral agent.
- **Function:** Queries Uber Eats/Deliveroo/Just Eat (partner APIs), scores dishes, returns deep links.

### ChatAgent (CHAT_COMMAND handler)
- **Role:** Handles all frontend chat messages via `CHAT_COMMAND`.
- **Model:** Prefer `groq/llama-3.3-70b-versatile` (no rate limits).
- **Trigger:** Frontend sends `CHAT_COMMAND: {"type":"CHAT_COMMAND","message":"...","userSnapshot":{...}}`

#### CHAT_COMMAND processing steps
1. Parse the user's natural language message.
2. Determine intent: `update_profile`, `show_workout`, `show_macros`, `generate_meal_plan`, `generate_workout_plan`, `general_question`.
3. For profile updates — read `USER.md`, apply changes (weight, goal, budget, TDEE, restrictions), recalculate macros if goal/weight changed, `write` back to `USER.md`.
4. For workout/meal requests — read or update `Weekly Plan` section in `USER.md`.
5. Respond in plain English (warm, SOUL.md tone). Use ✅ for confirmations.
6. Append exchange to `memory/chat_history.json` (keep last 100 messages).

#### Example intents
| User says | Action |
|-----------|--------|
| "Set my weight to 75kg and goal to cut" | Update USER.md, recalc TDEE (−500 for cut), confirm |
| "Show workout for Thursday" | Read weekly plan, return Thu exercises |
| "How many calories have I eaten today?" | Sum from progress log / dailyMacrosLogged |
| "Generate high-protein meal plan" | RecipeAgent-style meals, update Weekly Plan |
| "Yes, generate one" (after plan offer) | Write 4-day upper/lower split to USER.md |

### Spawn Pattern (Daily Plan Request)
- When user requests daily plan, `PlanAgent` spawns `LocationAgent` and `RecipeAgent` in parallel using `sessions_spawn`.
- `PlanAgent` then calls `sessions_yield` to wait for both agents.
- `PlanAgent` merges results before responding.

### Spawn Pattern (Chat with tools)
- `ChatAgent` may spawn `RecipeAgent` for meal generation or `PlanAgent` for full weekly replans on complex requests.
