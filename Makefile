FLUTTER := flutter
VERSION ?=
FLAVOR ?= dev

# Extract version components from pubspec.yaml
_version := $(shell grep '^version:' pubspec.yaml | sed 's/version: *//')
BUILD_NAME ?= $(word 1,$(subst +, ,$(_version)))
BUILD_NUMBER ?= $(word 2,$(subst +, ,$(_version)))

.PHONY: help get format format-check analyze test check run run-prod build build-dev clean tag release

help:           ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

get:            ## Install dependencies (flutter pub get)
	$(FLUTTER) pub get

format:         ## Format Dart source files in-place
	dart format lib/ test/

format-check:   ## Check formatting (dry-run, fails on unformatted code)
	dart format --output none --set-exit-if-changed lib/ test/

analyze:        ## Run flutter analyze
	$(FLUTTER) analyze

test:           ## Run unit tests
	$(FLUTTER) test --exclude-tags=golden

check: format-check analyze test   ## Run all checks (format-check + analyze + tests)

run:            ## Launch dev flavour on default device (flutter run --flavor dev)
	$(FLUTTER) run --flavor dev --dart-define=FLAVOR=dev

run-prod:       ## Launch prod flavour on default device
	$(FLUTTER) run --flavor prod --dart-define=FLAVOR=prod

build:          ## Build prod release APK (flutter build apk --release --flavor prod)
	$(FLUTTER) build apk --release --flavor prod \
		--dart-define=FLAVOR=prod \
		--build-name=$(BUILD_NAME) --build-number=$(BUILD_NUMBER)
	@mv build/app/outputs/flutter-apk/pantry-prod-release.apk \
	   build/app/outputs/flutter-apk/pantry-v$(BUILD_NAME).apk

build-dev:      ## Build dev release APK for sideloading
	$(FLUTTER) build apk --release --flavor dev \
		--dart-define=FLAVOR=dev \
		--build-name=$(BUILD_NAME) --build-number=$(BUILD_NUMBER)
	@mv build/app/outputs/flutter-apk/pantry-dev-release.apk \
	   build/app/outputs/flutter-apk/pantry-v$(BUILD_NAME)-dev.apk

clean:          ## Remove build artifacts (flutter clean)
	$(FLUTTER) clean

tag:            ## Create an annotated release tag: make tag VERSION=0.1.0
	@if [ -z "$(VERSION)" ]; then \
		echo "ERROR: VERSION is required. Usage: make tag VERSION=0.1.0"; \
		exit 1; \
	fi
	@if ! echo "$(VERSION)" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$$'; then \
		echo "ERROR: VERSION must be a semantic version (e.g. 0.1.0). Got '$(VERSION)'"; \
		exit 1; \
	fi
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "ERROR: Working tree is not clean. Commit or stash changes first."; \
		exit 1; \
	fi
	@if git rev-parse "v$(VERSION)" >/dev/null 2>&1; then \
		echo "ERROR: Tag v$(VERSION) already exists."; \
		exit 1; \
	fi
	$(MAKE) check
	sed -i '' 's/^version: .*/version: $(VERSION)+1/' pubspec.yaml
	git add pubspec.yaml
	git commit -m "chore: bump version to $(VERSION)"
	git tag -a "v$(VERSION)" -m "Release v$(VERSION)"
	@echo "Created tag v$(VERSION)"

release:        ## Create tag and push to origin: make release VERSION=0.1.0
	$(MAKE) tag VERSION=$(VERSION)
	git push origin "v$(VERSION)"
	@git rev-parse --abbrev-ref HEAD | xargs -I {} git push origin {}
	@echo "Pushed tag v$(VERSION) and branch. GitHub Actions will build the release."
	@echo "Monitor at: https://github.com/$$(git remote get-url origin | sed 's/.*://;s/\.git//')/actions"