#!/usr/bin/env bash
# Build staging APK, install, run Maestro flow that posts with image (requires signed-in user once).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MOBILE="$ROOT/crucially-mobile"
E2E="$ROOT/crucially-e2e"
export MAESTRO_APP_ID="${MAESTRO_APP_ID:-app.crucially.android}"

cd "$MOBILE"
flutter pub get
flutter build apk --debug --dart-define-from-file=.env-staging
adb install -r "$MOBILE/build/app/outputs/flutter-apk/app-debug.apk"

cd "$E2E"
maestro test flows/staging_post_with_image.yaml
