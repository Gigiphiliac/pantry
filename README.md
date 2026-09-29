# Pantry

Recipe management, shopping lists, and meal planning app.

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
| `make run` | Launch dev flavour on default device |
| `make run-prod` | Launch prod flavour (side-by-side with dev) |
| `make build` | Build prod release APK |
| `make build-dev` | Build dev release APK for sideloading |
| `make clean` | Remove build artifacts |
| `make tag VERSION=0.1.0` | Bump version, run checks, create annotated `v0.1.0` tag |
| `make release VERSION=0.1.0` | Tag + push — triggers GitHub Actions release |

> **Pre-commit**: the repo also ships a `githooks/pre-commit` hook that runs
> `make format-check && make analyze`. Install with `git config core.hooksPath githooks`
> or run `scripts/setup.sh`.

## Creating a Release

```bash
# Everything is already committed on main — one command does it all:
make release VERSION=0.3.0
```

This single command:
1. Runs `make check` (format + analyze + tests)
2. Updates `pubspec.yaml` `version:` to `0.3.0+1` and commits it
3. Creates annotated tag `v0.3.0`
4. Pushes the tag and branch to GitHub

The CI pipeline (`.github/workflows/release.yml`) then:
1. Runs format check, analyze, and tests
2. Builds a prod APK with `--build-name=0.3.0 --build-number=1`
3. Creates a GitHub Release with the APK attached as `pantry-v0.3.0.apk`

> **Version format**: `pubspec.yaml` uses `major.minor.patch+build`.
> The build number resets to `1` each release. The tag always gets a `v` prefix
> (`v0.3.0`) but the version inside the app omits it (`0.3.0`).

### Manual version override (if needed)

The version from `pubspec.yaml` is passed as `--build-name` and `--build-number`
to `flutter build apk`. To override for a one-off build:

```bash
make build BUILD_NAME=0.4.0 BUILD_NUMBER=1
```

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
│   ├── ocr/            # OCR feature extraction + ONNX classifier
│   └── units/          # Unit system (weight, volume, count)
├── db/                 # Drift database schema and migrations
├── features/
│   ├── shopping/       # Shopping lists
│   ├── recipes/        # Recipe CRUD + URL import + OCR
│   ├── meal_plans/     # Meal planning (week view, drag-and-drop slots)
│   ├── pantry/         # Ingredient library + stock tracking
│   └── settings/       # Unit & theme preferences
├── utils/              # Ingredient dedup (Jaro-Winkler)
└── app.dart            # App shell + navigation
```

## Tech Stack

| Concern | Choice |
|---|---|
| Framework | Flutter (Dart) |
| Local DB | Drift (SQLite ORM) |
| OCR | Google ML Kit (on-device) |
| State | Riverpod |
| API keys | flutter_secure_storage |
| Nutrition | Open Food Facts + USDA + schema.org (Planned) |

## Phase Roadmap

| Phase | Scope | Status |
|---|---|---|
| 1 | Shopping lists + ingredient dictionary | Complete |
| 2 | Recipes + AI import (URL, OCR) | Current |
| 3 | Meal planning — week view, drag-and-drop slots, recipe linking | In Progress |
| 4 | Nutrition goals + smart suggestions + pantry integration | Pending |