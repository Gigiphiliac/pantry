# Pantry

Recipe management, shopping lists, and meal planning app. Local-AI assisted, offline-capable.

Built with **Flutter** + **Drift** (SQLite ORM) + **Riverpod** state management.

---

## Quick Start

```bash
make get          # Install dependencies
make run          # Launch on connected device/emulator
make check        # Format check + analyze + tests (run before committing)
```

## Development

All common tasks are available through `make`:

| Command | Description |
|---|---|
| `make help` | Show all available commands |
| `make get` | Install dependencies (`flutter pub get`) |
| `make format` | Reformat Dart source files in-place |
| `make format-check` | Check formatting without modifying files |
| `make analyze` | Run `flutter analyze` |
| `make test` | Run unit tests |
| `make check` | Full pre-commit check: format + analyze + tests |
| `make run` | Launch debug app on default device |
| `make build` | Build Android release APK |
| `make clean` | Remove build artifacts |
| `make tag VERSION=0.1.0` | Create annotated `v0.1.0` tag (runs checks first) |
| `make release VERSION=0.1.0` | Tag + push — triggers GitHub Actions release |

> **Pre-commit**: the repo also ships a `githooks/pre-commit` hook that runs
> `make format-check && make analyze`. Install with `git config core.hooksPath githooks`
> or run `scripts/setup.sh`.

## Creating a Release

```bash
# Ensure everything is committed and pushed
git push origin main

# Tag and push — this triggers release.yml on GitHub Actions
make release VERSION=0.1.0
```

The CI pipeline will:
1. Run format check, analyze, and tests
2. Build an Android release APK (signed with debug keystore)
3. Create a GitHub Release with the APK attached

## Android Signing

The `release` build type is currently configured with `signingConfig = signingConfigs.debug`
(Android's auto-generated debug keystore). This produces a signed APK suitable for
testing on multiple devices.

For production (Play Store) releases, replace with a real keystore via GitHub Actions secrets:

| Secret | Purpose |
|---|---|
| `KEYSTORE_BASE64` | base64-encoded release keystore |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias in the keystore |
| `KEY_PASSWORD` | Key password |

Update `android/app/build.gradle.kts` to load these from environment variables
and switch `signingConfig` to `signingConfigs.release`.

## Architecture

```
lib/
├── core/
│   ├── ingredients/    # Ingredient name and line parsers
│   └── units/          # Unit system (weight, volume, count)
├── db/                 # Drift database schema and migrations
├── features/
│   ├── shopping/       # Shopping lists
│   ├── recipes/        # Recipe CRUD + URL import + OCR
│   ├── meal_plans/     # Meal planning
│   ├── pantry/         # Ingredient library + stock tracking
│   └── settings/       # LLM endpoint config
├── utils/              # Ingredient dedup (Jaro-Winkler)
└── app.dart            # App shell + navigation
```

## Tech Stack

| Concern | Choice |
|---|---|
| Framework | Flutter (Dart) |
| Local DB | Drift (SQLite ORM) |
| OCR | Google ML Kit (on-device) |
| LLM | Ollama / OpenAI-compatible endpoint |
| State | Riverpod |
| API keys | flutter_secure_storage |
| Nutrition | Open Food Facts + USDA + schema.org |

## Phase Roadmap

| Phase | Scope | Status |
|---|---|---|
| 1 | Shopping lists + ingredient dictionary | Current |
| 2 | Recipes + AI import (URL, OCR) + nutrition | Pending |
| 3 | Meal planning + nutrition goals + suggestions | Pending |