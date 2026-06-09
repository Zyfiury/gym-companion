# SKILL.md — recipe_with_video

## Objective
Generate step-by-step cooking instructions for a given meal and embed a matching YouTube cooking video via the YouTube Data API.

## Input
- `meal_name`: e.g. "High-Protein Scrambled Eggs with Spinach"
- `meal_description`: short description
- `required_macros`: e.g. `{ "protein": 30, "carbs": 50, "fat": 15, "calories": 450 }`
- `dietary_restrictions`: from `USER.md`

## Output
```json
{
  "mealType": "Breakfast",
  "name": "<Meal Name>",
  "description": "<Detailed Description>",
  "steps": ["Step 1...", "Step 2..."],
  "macros": { "calories": 0, "protein": 0, "carbs": 0, "fat": 0 },
  "youtubeVideoId": "<11-char video ID>",
  "youtubeUrl": "https://www.youtube.com/watch?v=<id>"
}
```

## Steps
1. Receive inputs from spawning agent (PlanAgent or RecipeAgent).
2. Generate recipe steps aligned with `required_macros` and `dietary_restrictions`.
3. **YouTube Data API** — search for a matching tutorial:
   - Read `YOUTUBE_API_KEY` from environment.
   - `GET https://www.googleapis.com/youtube/v3/search?part=snippet&q=<meal_name> cooking tutorial&type=video&maxResults=5&key=<key>`
   - Pick the best match (relevance, reasonable duration, clear title).
4. Embed `youtubeVideoId` in the response.
5. If API key missing or request fails, fall back to `web_search` and extract a video ID from results; log a warning.

## Tools
- `exec` / HTTP client for YouTube Data API
- `web_search` (fallback)
- Internal macro estimation logic

## Environment
- `YOUTUBE_API_KEY` — required for production; user must set in OpenClaw secrets or `.env`

## Considerations
- Strict dietary compliance.
- Prefer videos under 15 minutes for weeknight meals.
- Match SOUL.md tone in recipe descriptions.
