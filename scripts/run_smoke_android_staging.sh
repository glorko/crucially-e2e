#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MOBILE="$ROOT/crucially-mobile"
E2E="$ROOT/crucially-e2e"
export MAESTRO_APP_ID_ANDROID="${MAESTRO_APP_ID_ANDROID:-app.crucially.android}"

cd "$MOBILE"
flutter pub get
flutter build apk --debug --dart-define-from-file=.env-staging
adb install -r "$MOBILE/build/app/outputs/flutter-apk/app-debug.apk"

cd "$E2E"
maestro test flows/app_loads_smoke.yaml
