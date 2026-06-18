# Pantry — Project Plan

## Context

Building "Pantry": a Flutter iOS app combining recipe management, shopping lists, and meal planning. Local-AI assisted (ML Kit on-device OCR, configurable external LLM). Personal use, iPhone-first, offline-capable. Directory to rename from `tbd` → `pantry`.

---

## Stack Decisions

| Concern | Decision | Rationale |
|---|---|---|
| Framework | Flutter (Dart) | Native iOS performance, ML Kit plugins, camera access |
| Local DB | Drift (SQLite ORM) | Relational joins for ingredient deduplication, type-safe |
| OCR | Google ML Kit (on-device) | Free, no network, excellent accuracy, Flutter plugin exists |
| LLM | Configurable endpoint (Ollama/OpenAI-compat API) | LAN or cloud, features disabled + settings prompt if unconfigured |
| Nutrition | Open Food Facts API + USDA fallback + schema.org scrape | Free, good AU coverage, auto-populated from recipe URLs |
| Backend | None (Phase 1–2) | Local-first, direct API calls, re-evaluate in Phase 3 |
| Recipe import | User-initiated URL paste (Paprika pattern) | No ToS violation, user triggers single fetch |

---

## Data Model (Drift schema)

```
ingredients          — canonical name, preferred unit, aliases (JSON), nutrition ref
ingredient_aliases   — alias string → ingredient_id (for fuzzy dedup)
shopping_lists       — id, name, created_at, archived_at
shopping_list_stores — list_id, store_name, sort_order
shopping_list_sections — store_id, section_name, sort_order
shopping_list_items  — section_id, ingredient_id (nullable), raw_text, qty, unit, checked
recipes              — id, name, source_url, source_type (manual/url/ocr), servings, instructions, nutrition_json
recipe_ingredients   — recipe_id, ingredient_id, qty, unit, notes
meal_plans           — id, name, start_date, end_date
meal_plan_days       — plan_id, date
meal_slots           — day_id, slot_name (Breakfast/Lunch/Dinner/Snack/custom), recipe_id (nullable), notes
```

---

## Ingredient Deduplication Logic

1. On add (manual or from recipe): normalise string (lowercase, trim)
2. Exact match against `ingredient_aliases` → merge immediately
3. Fuzzy match (Jaro-Winkler or Levenshtein) against canonical names + aliases
   - Score ≥ 0.92 → auto-merge silently
   - Score 0.75–0.91 → show prompt: "Is 'crushed tomatoes' the same as 'canned tomatoes'? [Merge] [New ingredient]"
   - Score < 0.75 → new ingredient created
4. If LLM configured: low-confidence cases can be sent to LLM for resolution
5. Quantity aggregation: convert incoming unit → canonical unit using unit-conversion table; flag mismatched unit families for user

---

## Phases

### Phase 1 — Shopping Lists (ship first)

- Multi-list support (create, name, archive lists)
- Store / section hierarchy: `+` button → "New Store" / "New Section" contextual buttons
- iOS Notes-style checkboxes per item
- Ingredient canonical dictionary + alias table (foundation for Phase 2)
- Manual item entry with deduplication confidence prompts
- Settings screen: LLM endpoint config (URL + API key), model name

**Flutter packages:** `drift`, `flutter_slidable`, `provider` or `riverpod`

---

### Phase 2 — Recipes + AI Import

- Recipe creation (manual form: name, servings, ingredients, steps, nutrition)
- Recipe library: search by ingredient, difficulty, time
- Serving size scaling (multiply ingredient quantities)
- URL import: paste URL → fetch HTML → LLM parses → structured recipe preview → save
  - Falls back gracefully: schema.org JSON-LD parsed first (no LLM needed for well-structured sites)
  - LLM used for unstructured HTML (requires configured endpoint)
- Image/OCR import: camera or photo library → ML Kit text extraction → LLM structures into recipe
  - OCR always available (on-device); LLM structuring requires configured endpoint
- Nutrition auto-population: schema.org scrape → Open Food Facts per-ingredient → USDA fallback
- "Add to shopping list" from recipe: ingredient dedup + quantity aggregation into selected list
- Recipe ↔ meal slot linking

**Flutter packages:** `google_mlkit_text_recognition`, `image_picker`, `http`, `html` (parsing)

---

### Phase 3 — Meal Planning + Smart Suggestions

- Meal plan creation: name, date range
- Day view: configurable meal slots (add/remove/rename)
- Each slot: link recipe or write free-text note
- Nutrition goal tracking: daily targets, progress from linked recipes
- Smart recipe suggestions: match pantry/available ingredients, meet nutrition targets
  - LLM-powered if configured, else simple tag-matching fallback
- "Generate shopping list from meal plan" — aggregates all recipe ingredients, deduplicates, outputs to new/existing list

---

## LLM Feature Gating

All LLM-dependent features check `LlmConfig.isConfigured` before rendering. If not configured:
- URL import: "LLM not configured — [Go to Settings]" banner (schema.org-only import still works)
- OCR structuring: same banner
- Smart suggestions (Phase 3): "Configure LLM to enable smart suggestions"

Settings screen always accessible from nav. Config persisted in Drift (or `flutter_secure_storage` for API key).

---

## Agentic Scaffolding

All plans live in `pantry/plans/` as dated Markdown files: `YYYY-MM-DD-<slug>.md`.
An `CLAUDE.md` file at the project root gives any agent (Claude Code, CI, etc.) the standing context it needs without re-grilling the user each session.

### `CLAUDE.md` must cover:
- App name, purpose, target platform
- Stack decisions (Flutter, Drift, ML Kit, configurable LLM)
- Data model summary
- Phase roadmap with current phase highlighted
- LLM feature-gating rules
- Ingredient deduplication thresholds
- Conventions: Dart style, file structure, migration discipline

### Plan file convention:
- Stored at `pantry/plans/YYYY-MM-DD-<slug>.md`
- Each plan begins with a **Context** section (why, what prompted it, intended outcome)
- Plans are append-only — never delete old plan files

---

## Project Initialisation Steps

1. Rename directory `tbd` → `pantry`
2. `flutter create pantry --platforms ios` (personal project, no org identifier)
3. Create `pantry/CLAUDE.md` with full project context (stack, data model, phases, conventions)
4. Create `pantry/plans/` directory; move this plan in as `pantry/plans/2026-06-08-phase-1-shopping-lists.md`
5. Add Drift, ML Kit, Riverpod, etc. to `pubspec.yaml`
6. Scaffold nav shell: bottom nav bar with 3 tabs (Lists, Recipes, Meal Plans)
7. Implement Drift schema migrations from day one (versioned)
8. Phase 1 UI: Shopping list CRUD, store/section hierarchy, item checkboxes

---

## Verification

- Phase 1: Create a list, add stores, add sections, add items, check them off, archive list, create second list
- Phase 2: Paste a RecipeTin URL → recipe imports correctly; take photo of handwritten recipe → OCR + LLM structures it; add recipe ingredients to shopping list → dedup prompt fires on collision
- Phase 3: Build a week meal plan → generate shopping list → nutrition totals match sum of linked recipes
