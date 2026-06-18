# Pantry — Agent Context

Personal iOS app: recipe management, shopping lists, meal planning. Local-AI assisted. iPhone-first, offline-capable.

---

## Stack

| Concern | Decision |
|---|---|
| Framework | Flutter (Dart) |
| Local DB | Drift (SQLite ORM) |
| OCR | Google ML Kit (on-device, `google_mlkit_text_recognition`) |
| LLM | Configurable endpoint — Ollama on LAN or any OpenAI-compat API |
| Nutrition | Open Food Facts API + USDA FoodData Central fallback + schema.org scrape |
| Backend | None (Phase 1–2); local-first, direct API calls |
| Recipe import | User-initiated URL paste — fetch HTML client-side, parse with LLM or schema.org JSON-LD |
| State management | Riverpod |
| API key storage | `flutter_secure_storage` |

---

## Data Model (Drift schema)

```
ingredients            canonical name, preferred_unit, nutrition_ref
ingredient_aliases     alias string → ingredient_id  (fuzzy dedup lookup table)
shopping_lists         id, name, created_at, archived_at
shopping_list_stores   list_id, store_name, sort_order
shopping_list_sections store_id, section_name, sort_order
shopping_list_items    section_id, ingredient_id (nullable), raw_text, qty, unit, checked
recipes                id, name, source_url, source_type (manual/url/ocr), servings, instructions, nutrition_json
recipe_ingredients     recipe_id, ingredient_id, qty, unit, notes
meal_plans             id, name, start_date, end_date
meal_plan_days         plan_id, date
meal_slots             day_id, slot_name, recipe_id (nullable), notes
```

---

## Ingredient Deduplication

1. Normalise: lowercase, trim
2. Exact match in `ingredient_aliases` → auto-merge
3. Fuzzy match (Jaro-Winkler):
   - ≥ 0.92 → auto-merge silently
   - 0.75–0.91 → prompt user: [Merge] or [New ingredient]
   - < 0.75 → new ingredient
4. LLM (if configured) handles low-confidence cases
5. Unit aggregation: convert to canonical unit; flag mismatched unit families

---

## LLM Feature Gating

All LLM features check `LlmConfig.isConfigured`. If false:
- Show inline banner: "[Feature] requires LLM — [Go to Settings]"
- schema.org-only URL import still works without LLM
- On-device OCR still works without LLM (structuring step is gated)

LLM config stored in `flutter_secure_storage`: endpoint URL, API key, model name.

---

## Phase Roadmap

| Phase | Scope | Status |
|---|---|---|
| **1** | **Shopping lists — full UI + ingredient dictionary** | **Current** |
| 2 | Recipes + AI import (URL, OCR) + nutrition | Pending |
| 3 | Meal planning + nutrition goals + smart suggestions | Pending |

---

## Conventions

- **Dart style**: follow `dart format`, no trailing commas suppressed, prefer `final`
- **File structure**: `lib/features/<feature>/` — one directory per feature (shopping, recipes, meal_plans, settings)
- **Drift migrations**: always versioned; never modify a past migration file
- **Plans**: all plans stored in `pantry/plans/YYYY-MM-DD-<slug>.md`; append-only, never delete
- **No org prefix**: personal project, no reverse-domain identifier
- **Australian English**: all user-facing strings and comments use AU spelling

---

## Key Flutter Packages

```yaml
drift: ^2.x                        # SQLite ORM
drift_flutter: ^0.x                # Flutter integration for Drift
riverpod: ^2.x                     # State management
google_mlkit_text_recognition: ^x  # On-device OCR
image_picker: ^x                   # Camera + photo library
flutter_secure_storage: ^x         # API key storage
flutter_slidable: ^x               # Swipe actions on list items
http: ^x                           # HTTP client
html: ^x                           # HTML parsing for recipe scrape
```
