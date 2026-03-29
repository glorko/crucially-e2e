#!/usr/bin/env bash
# Build staging APK, install, run Maestro flow that posts with image.
# Uses E2E_SKIP_AUTH (Firebase anonymous) + E2E_INJECT_IMAGE (seed e2e_1x1.png into app files via run-as); cold-starts via adb force-stop
# because Maestro launchApp stopApp:true was flaky for the feed shell.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MOBILE="$ROOT/crucially-mobile"
E2E="$ROOT/crucially-e2e"
export MAESTRO_APP_ID="${MAESTRO_APP_ID:-app.crucially.android}"
E2E_TMP_ON_DEVICE="/data/local/tmp/e2e_1x1.png"

cd "$MOBILE"
flutter pub get
# Ensure dart-define changes are not served from a stale kernel snapshot.
rm -rf "$MOBILE/.dart_tool/flutter_build"
flutter build apk --debug \
  --dart-define-from-file=.env-staging \
  --dart-define=E2E_INJECT_IMAGE=true \
  --dart-define=E2E_SKIP_AUTH=true \
  --dart-define=E2E_TOS_ACCEPTED=true
adb install -r "$MOBILE/build/app/outputs/flutter-apk/app-debug.apk"
adb push "$E2E/assets/e2e_1x1.png" "$E2E_TMP_ON_DEVICE"
adb shell run-as "$MAESTRO_APP_ID" cp "$E2E_TMP_ON_DEVICE" files/e2e_1x1.png

cd "$E2E"
adb shell am force-stop "$MAESTRO_APP_ID" || true
maestro test flows/staging_post_with_image.yaml
