#!/usr/bin/env bash
# Build staging APK, install, run Maestro flow that posts with image.
# Prerequisite: sign in on the emulator (Google) before running Maestro — no E2E auth shortcuts.
# addMedia in the flow seeds the device gallery; pick_first_gallery_image.yaml taps the system picker.
# Set FULL_RESET=1 to adb uninstall the app first (wipes session; sign in again after install).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MOBILE="$ROOT/crucially-mobile"
E2E="$ROOT/crucially-e2e"
export MAESTRO_APP_ID="${MAESTRO_APP_ID:-app.crucially.android}"

if [[ "${FULL_RESET:-0}" == "1" ]]; then
  adb uninstall "$MAESTRO_APP_ID" 2>/dev/null || true
fi

cd "$MOBILE"
flutter clean
flutter pub get
flutter build apk --debug \
  --dart-define-from-file=.env-staging

adb install -r "$MOBILE/build/app/outputs/flutter-apk/app-debug.apk"

cd "$E2E"
adb shell am force-stop "$MAESTRO_APP_ID" || true
maestro test flows/staging_post_with_image.yaml
