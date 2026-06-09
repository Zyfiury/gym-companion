# SKILL.md — workout_video

## Objective
Fetch YouTube demo videos for exercises in the weekly workout plan.

## Input
Exercise name from Weekly Plan, e.g. "Bench Press 4×8"

## API
```
GET https://www.googleapis.com/youtube/v3/search?part=snippet&q={exercise}+form+tutorial&type=video&maxResults=1&key={YOUTUBE_API_KEY}
```

## Steps
1. Strip sets/reps from exercise name (e.g. "Bench Press").
2. Check local cache for existing video ID.
3. If not cached, call YouTube Data API.
4. Cache video ID in frontend localStorage (`gymapp_exercise_video_cache`).
5. Return thumbnail URL and video ID for modal player.

## Cache format
```json
{ "bench press": { "videoId": "abc123", "title": "...", "thumbnail": "..." } }
```

## Tools
- YouTube Data API (YOUTUBE_API_KEY from .env)
- `read` (USER.md Weekly Plan workouts)
