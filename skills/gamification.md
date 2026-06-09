# SKILL.md — gamification

## Objective
Track XP, streaks, levels, and achievements. Store in USER.md Gamification section.

## XP rules
| Action | XP |
|--------|-----|
| Log workout | 10 |
| Log meal (chat or barcode) | 5 |
| Barcode scan | 5 |
| Share to feed | 3 |
| 7-day streak bonus | 50 |

## Level formula
`level = floor(sqrt(xp / 100)) + 1`

## Streak rules
- Consecutive days with at least one workout OR meal log
- Resets if a full day passes with no activity

## Achievements
| ID | Name | Condition |
|----|------|-----------|
| macro_streak_7 | 7-day macro streak | streak >= 7 |
| first_pr | 1st PR lifted | personalRecords.length > 0 |
| first_barcode | First barcode scan | barcodeScans >= 1 |
| shared_5 | Shared 5 posts | postsShared >= 5 |
| workout_10 | 10 workouts logged | workoutsLogged >= 10 |
| meal_20 | 20 meals logged | mealsLogged >= 20 |

## Steps
1. On workout/meal/barcode/share event, read Gamification from USER.md.
2. Increment counters, award XP, check achievements.
3. Update streak based on lastActiveDate.
4. Write back to USER.md Gamification section.
5. Include XP gain in chat confirmation when applicable.

## USER.md format
```markdown
## Gamification
- **XP:** 125
- **Level:** 2
- **Streak:** 5 days
- **Achievements:** [first_barcode, meal_20]
```

## Tools
- `read`, `write` (USER.md)
