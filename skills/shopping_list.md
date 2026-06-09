# SKILL.md - shopping_list

## Objective
Generate a daily shopping list with exact items and estimated prices, within the user's weekly budget, for the 'Cook myself' nutrition mode.

## Input
- Daily meal plan (from PlanAgent, with required ingredients and estimated quantities)
- User's current location (e.g., "London", "SW1A 0AA")
- Weekly food budget (from `USER.md`)

## Output
Returns a JSON object representing the shopping list:
```json
{
  "supermarket": "<Cheapest Supermarket Name>",
  "totalEstimatedCost": "£<Total Cost>",
  "items": [
    {"item": "<Item Name>", "quantity": "<Quantity>", "price": "£<Price>"},
    // ... more items
  ]
}
```

## Steps
1. Receive `daily_meal_plan` (including ingredient needs) and `user_location` from the spawning agent.
2. **Call `LocationAgent`**: Spawn `LocationAgent` (ephemeral) with a task like `"findcheapestsupermarkets near <user_location> for <list_of_ingredients>"`.
3. **`sessions_yield`**: Wait for `LocationAgent` to return its JSON response containing supermarket and pricing information (simulating Trolley API or similar).
4. **Process `LocationAgent` Response**: Extract the `supermarket`, `totalEstimatedCost`, and `items` array from the JSON.
5. **Budget Check**: Ensure the `totalEstimatedCost` is within the user's `weekly_food_budget` (pro-rated for a day or considering remaining budget).
6. **Format & Return**: Construct and return the `shoppingList` JSON object as defined in the `Output` section.

## Tools to Use
- `sessions_spawn` (to call LocationAgent)
- `sessions_yield` (to wait for LocationAgent results)
- Internal calculation logic (for budget management, item selection, pro-rating budget)

## Environment
- `TROLLEY_API_KEY` — UK supermarket pricing (or equivalent API via LocationAgent)
- `GOOGLE_PLACES_API_KEY` — nearby store discovery

## Important Considerations
- **API Keys & Security:** Read keys from environment only; never commit secrets.
- **Pricing Accuracy:** Real-time pricing is volatile; results will be estimates.
- **Ingredient Matching:** Accurate matching of generic ingredients to specific supermarket products is challenging.
