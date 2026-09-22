#!/bin/sh
#
# Pantry setup script
# Configures githooks, installs dependencies, and prepares the dev environment.
#
set -e

echo "📦 Installing Flutter dependencies..."
flutter pub get

echo "🔗 Configuring githooks..."
git config core.hooksPath githooks
echo "   hooksPath set to githooks/"

echo "✅ Setup complete!"