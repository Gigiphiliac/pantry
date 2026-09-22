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

## Development Workflow

All common tasks go through `make`. The Makefile is the canonical local interface.

| Command | What it does |
|---|---|
| `make get` | `flutter pub get` |
| `make format` | Reformat Dart source in-place |
| `make format-check` | Dry-run format check (fails on unformatted code) |
| `make analyze` | `flutter analyze` |
| `make test` | `flutter test --exclude-tags=golden` |
| `make check` | `format-check` + `analyze` + `test` — run before committing |
| `make run` | `flutter run` on default device |
| `make build` | `flutter build apk --release` |
| `make clean` | `flutter clean` |
| `make tag VERSION=0.1.0` | Validate, run checks, create annotated `v0.1.0` tag |
| `make release VERSION=0.1.0` | Tag + push branch + push tag — triggers GitHub Actions release |

Githooks are in `githooks/` and run `make format-check && make analyze` on every commit.
Install: `git config core.hooksPath githooks` or run `scripts/setup.sh`.

CI (`.github/workflows/ci.yml`) runs the same checks on push/PR to `main`.

---

## Releases

```bash
make release VERSION=0.2.0
```

Creates `v0.2.0`, pushes it to GitHub, and triggers `.github/workflows/release.yml`:
format check → analyze → tests → `flutter build apk --release` → GitHub Release with APK.

The `release` build type uses `signingConfig = signingConfigs.debug` (Android's auto-generated debug keystore): APK is signed, R8-minified, installable on any device, no debug banner.

For production, configure secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` and switch to `signingConfigs.release`.

---

## Test Layout

Tests mirror `lib/` structure under `test/`:

```
test/
├── core/
│   ├── ingredients/ingredient_parser_test.dart    29 tests
│   └── units/unit_system_test.dart                30 tests
├── features/recipes/models/ingredient_name_parser_test.dart  14 tests
├── utils/ingredient_dedup_test.dart               18 tests
└── widget_test.dart                               (placeholder)
```

Drift-dependent tests use `AppDatabase.connect(NativeDatabase.memory())` for in-memory SQLite — no device needed.

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
recipe_ingredient_alternatives  ingredient_id, qty, unit, sort_order
recipe_steps                    recipe_id, step_number, content
meal_plans             id, name, start_date, end_date
meal_plan_days         plan_id, date
meal_slots             day_id, slot_name, recipe_id (nullable), notes
pantry_items           ingredient_id, tier, user_confirmed
pantry_stock_categories        name, sort_order
pantry_stock          ingredient_id, category_id, on_hand_qty, on_hand_unit, notes
```

The database class exposes `AppDatabase.connect(QueryExecutor)` for testing.

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