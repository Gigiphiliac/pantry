# TODO

## Active

### Shopping list item — improve fallback store assignment

When adding an ingredient from a recipe (or elsewhere) to a shopping list, if no
store/section match is found, the item is assigned to the first store as
ungrouped. This is not final behaviour — it should prompt the user or create a
configurable default.

**Source:** `lib/features/shopping/shopping_providers.dart:319`
**Status:** Needs design decision — prompt user, configurable default, or
auto-create a store?

### Meal planner — add provider and widget tests

The meal planner (Phase 3 initial scope) was implemented without tests. Needs:
- `MealPlanOps` unit tests (upsert, swap, clear) using in-memory Drift
- `MealSlotsForWeekProvider` stream provider tests
- Widget tests for slot cell rendering, drag-and-drop interactions (drag source
  rendering, drop target highlighting)

**Source:** `lib/features/meal_plans/`
**Status:** Needed before Phase 3 can ship as stable

## Planned

### Nutrition API — implement auto-population

The schema has `recipes.nutrition_json` and `ingredients.nutrition_ref` columns
but no code populates them. Intended pipeline:
- schema.org JSON-LD scrape from recipe URL (no LLM needed)
- Open Food Facts API per-ingredient lookup
- USDA FoodData Central fallback

**Status:** Deferred — not started, no LLM dependency