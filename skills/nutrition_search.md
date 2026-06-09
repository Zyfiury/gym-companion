# SKILL.md — nutrition_search

## Objective
Search Open Food Facts for food items and log macros to USER.md Food Log section.

## Input
Natural language from CHAT_COMMAND, e.g.:
- "Log 200g chicken breast"
- "Log 150g greek yogurt"

## API
```
GET https://world.openfoodfacts.org/cgi/search.pl?search_terms={query}&json=1&page_size=5
GET https://world.openfoodfacts.org/api/v2/product/{barcode}.json
```

## Steps
1. Parse amount (grams) and food name from message.
2. Search Open Food Facts API.
3. Scale per-100g macros to requested amount.
4. Append row to **Food Log** table in USER.md.
5. Update daily macro totals in profile snapshot.
6. Award 5 XP (meal log) via Gamification section.
7. Reply with macros and daily total.

## Output example
"✅ Logged 200g Chicken breast — 330 kcal, P 62g, C 0g, F 7g. Today: 850/2200 kcal."

## Tools
- `read`, `write` (USER.md)
- Open Food Facts API (no key required)
