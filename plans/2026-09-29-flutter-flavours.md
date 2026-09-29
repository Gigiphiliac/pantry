# Flutter Flavours — dev + prod

2026-09-29

## Summary

Added separate `dev` and `prod` flavours so debug/release builds don't overwrite
each other on-device. Both platforms are configured; iOS needs the manual Xcode
scheme steps below before `flutter run --flavor dev` (or prod) works on a device.

## Already implemented (automated)

### Android (`android/app/build.gradle.kts`)

- `productFlavors { dev, prod }` with `flavorDimensions = ["app"]`
- `prod` → `applicationId = "com.gigi.pantry"`, `resValue("string", "app_name", "pantry")`
- `dev` → `applicationId = "com.gigi.pantry.dev"`, `resValue("string", "app_name", "pantry-dev")`
- `AndroidManifest.xml` uses `@string/app_name` (resolves per flavour)

### Dart (`lib/main.dart`)

- `const appFlavour` reads `--dart-define=FLAVOR` at compile time (default `dev`)
- Exported `isDev` / `isProd` getters for future flavour-dependent logic

### Makefile

| Command | Runs |
|---|---|
| `make run` | `flutter run --flavor dev` |
| `make run-prod` | `flutter run --flavor prod` |
| `make build` | `flutter build apk --release --flavor prod` |
| `make build-dev` | `flutter build apk --release --flavor dev` |

All existing `make check` / `format` / `analyze` / `test` targets are
flavour-agnostic — no changes needed.

### CI / Release

- `.github/workflows/release.yml` APK path → `app-prod-release.apk`
- CI (`ci.yml`) unchanged

---

## iOS — still needs manual Xcode setup

Flutter's `--flavor` flag on iOS requires Xcode schemes. The following steps
have **not** been automated because the Xcode project format is fragile to
script and the user prefers to do this once manually.

### Prerequisites

The stub xcconfig files exist at:
- `ios/Flutter/prod.xcconfig`
- `ios/Flutter/dev.xcconfig`

### Steps (in Xcode)

1. **Open the Xcode project**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Duplicate the "Runner" scheme** (for `dev`)
   - Menu: Product → Scheme → Manage Schemes…
   - Select the `Runner` scheme → gear icon → Duplicate
   - Name it `dev`
   - (The original `Runner` scheme becomes your `prod` scheme — rename it to
     `prod` for clarity)

3. **Configure the `dev` scheme**
   - In Manage Schemes, double-click the `dev` scheme (or select and hit Edit)
   - **Build** tab → Pre-actions: ensure the "Run Prepare Flutter Framework
     Script" is present (should be copied from the original scheme)
   - **Run** tab → Build Configuration: `Debug`
   - **Archive** tab → Build Configuration: `Release`
   - Close the scheme editor.

4. **Set bundle ID and display name for `dev`**
   - In the project navigator, select the `Runner` project → target `Runner`
     → **Build Settings** tab
   - Click the `+` → **Add User-Defined Setting**
     - Key: `FLAVOR` → set to `dev` for the `dev` configuration
     - Key: `PRODUCT_BUNDLE_IDENTIFIER` → set to `com.gigi.pantry.dev` for the
       `dev` configuration (and leave `com.gigi.pantry` for others)
     - Key: `APP_DISPLAY_NAME` → set to `Pantry Dev` for the `dev` configuration
       and `Pantry` for others
   - In `ios/Runner/Info.plist`, change `CFBundleDisplayName` to
     `$(APP_DISPLAY_NAME)` (it is currently the literal `Pantry`)

5. **Wire the xcconfig files**
   - In Build Settings → Info → **Configuration**, ensure:
     - `Debug` config points to `Flutter/dev.xcconfig` for the dev scheme
     - `Release` config points to `Flutter/prod.xcconfig` for the prod scheme
   - (Flutter's `Generated.xcconfig` is already included by both)

6. **Clean and test**
   ```bash
   flutter clean
   flutter run --flavor dev
   flutter run --flavor prod   # should pick up the prod scheme
   ```

### Verification

- Both builds succeed
- Two icons appear on your home screen (if installed side-by-side):
  - `Pantry` (prod, `com.gigi.pantry`)
  - `Pantry Dev` (dev, `com.gigi.pantry.dev`)