# SKILL.md - delivery_scan

## Objective
Query delivery platform APIs (Uber Eats, Deliveroo, Just Eat) to find nearby restaurants, score dishes against user's macro targets and budget, and return top matches with one-tap deep links.

## Input
- User's current location (from PlanAgent, e.g., "London", "SW1A 0AA")
- Daily macro targets (from PlanAgent)
- Weekly food budget (from `USER.md`)
- Dietary restrictions (from `USER.md`)

## Output
Returns a JSON object containing a list of recommended dishes:
```json
{
  "deliveryOptions": [
    {
      "restaurant": "<Restaurant Name>",
      "dish": "<Dish Name>",
      "macros": "<Macros String e.g., 600 kcal, 45g protein, 60g carbs, 20g fat>",
      "price": "£<Price>",
      "score": "<Score e.g., 9/10>",
      "deepLink": "<Platform Deep Link>"
    }
    // ... up to 3 top matches
  ]
}
```

## Steps
1. Receive `user_location`, `daily_macro_targets`, `weekly_food_budget`, and `dietary_restrictions` from the spawning agent.
2. **Call `LocationAgent`**: Spawn `LocationAgent` (ephemeral) with a task like `"findhomedeliveryrestaurants near <user_location>"` to get a list of nearby restaurants available on delivery platforms.
3. **`sessions_yield`**: Wait for `LocationAgent` to return its JSON response.
4. **Query Delivery Platform APIs (Simulated):** For each restaurant from `LocationAgent`'s response, simulate querying Uber Eats, Deliveroo, and/or Just Eat partner APIs for menus and dish details.
   - If real partner APIs were integrated, this step would involve direct API calls.
   - For now, use `web_search` with queries like `"<restaurant_name> menu Uber Eats <user_location>"` to find sample dishes and macro information, or use predefined demo data.
5. **Score Dishes:** For each retrieved dish:
   - Estimate macro content (if not directly provided).
   - Calculate a score based on macro adherence to `daily_macro_targets`, `price` (within `weekly_food_budget`), and compliance with `dietary_restrictions`.
6. **Filter & Rank:** Aggregate all scored dishes and select the top 3 matches.
7. **Format & Return:** Construct and return the `deliveryOptions` JSON object as defined in the `Output` section, including one-tap deep links (simulated or real if APIs integrated).

## Tools to Use
- `sessions_spawn` (to call LocationAgent)
- `sessions_yield` (to wait for LocationAgent results)
- `web_search` (for simulating delivery platform queries, menu fetching)
- Internal calculation logic (for scoring, macro estimation)

## Environment
- `GOOGLE_PLACES_API_KEY` — restaurant discovery via LocationAgent
- Delivery partner APIs: use if available; otherwise return demo data with realistic macros and deep links

## Important Considerations
- **API Access:** Requires partner API access/agreements with delivery platforms. Simulation is necessary without these.
- **Macro Estimation Accuracy:** Estimating macros from dish names/descriptions is challenging; requires robust data sources.
- **Dynamic Pricing/Availability:** Prices and availability change rapidly; results are estimates.
- **Deep Link Generation:** Ensure accurate and functional deep link construction.
