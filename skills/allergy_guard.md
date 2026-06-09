# Allergy Guard Skill

## Purpose
Block unsafe foods, meals, barcode products, and video titles based on user allergies and diet preferences.

## User fields (USER.md / UserData)
- `allergies`: list of allergen keys (peanuts, tree_nuts, dairy, eggs, gluten, soy, shellfish, fish, sesame)
- `excludedIngredients`: free-text ingredients to avoid
- `dietType`: omnivore | vegetarian | vegan

## Chat commands
- "I'm allergic to dairy" → add allergy
- "What are my allergies?" → list allergies
- Food log with allergen → block with warning

## Barcode
Check product name + allergen tags before logging. Return blocked message if conflict.

## Meal generation
Filter meal pool through AllergyGuard before suggesting or swapping meals.
