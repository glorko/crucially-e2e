#!/usr/bin/env bash
# Run Maestro E2E tests (between-devices only). Assumes crux (backend + 2 app instances) is already running.
# Start crux separately (e.g. from repo root: crux -c config.yaml).
#
# Usage:
#   ./scripts/run-e2e.sh [--ios-only|--android-only] [--with-notifications]
#   iOS = author (post, comment, delete). Android = receiver (see post, see comment, assert comment gone after sync).
set -e

# Ensure Maestro is on PATH (default install: ~/.maestro/bin)
if [ -d "${HOME}/.maestro/bin" ]; then
  export PATH="${HOME}/.maestro/bin:${PATH}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E2E_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_ID_IOS="${MAESTRO_APP_ID_IOS:-app.crucially.ios}"
APP_ID_ANDROID="${MAESTRO_APP_ID_ANDROID:-app.crucially.android}"
DEVICE_ID_IOS="${MAESTRO_DEVICE_ID_IOS:-90266925-B62F-4741-A89E-EF11BFA0CC57}"
DEVICE_ID_ANDROID="${MAESTRO_DEVICE_ID_ANDROID:-emulator-5554}"

PLATFORM=""
RUN_NOTIFICATIONS=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --ios-only) PLATFORM=ios; shift ;;
    --android-only) PLATFORM=android; shift ;;
    --with-notifications) RUN_NOTIFICATIONS=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Unique post text for this run (timestamp so we don't match old posts with same text)
export MAESTRO_E2E_POST_TEXT="${MAESTRO_E2E_POST_TEXT:-e2e post $(date +%s)}"
export MAESTRO_E2E_COMMENT_TEXT="${MAESTRO_E2E_COMMENT_TEXT:-e2e comment $(date +%s)}"
echo "E2E post text: $MAESTRO_E2E_POST_TEXT"
echo "E2E comment text: $MAESTRO_E2E_COMMENT_TEXT"

# Optional: reset test data before tests (script or HTTP)
if [ -n "${E2E_RESET_SCRIPT:-}" ] && [ -x "$E2E_RESET_SCRIPT" ]; then
  echo "Resetting test data: $E2E_RESET_SCRIPT"
  DATABASE_URL="${DATABASE_URL:-postgres://postgres:postgres@localhost:5440/crucially?sslmode=disable}" \
  REDIS_URL="${REDIS_URL:-redis://localhost:6382}" \
  "$E2E_RESET_SCRIPT" || true
  sleep 2
elif [ -n "${E2E_RESET_URL:-}" ]; then
  echo "Resetting test data: $E2E_RESET_URL"
  curl -s -X POST "$E2E_RESET_URL" || true
  sleep 2
fi

run_maestro() {
  local app_id=$1
  local flow_name=$2
  local device_id=${3:-}
  export MAESTRO_APP_ID="$app_id"
  if [ -n "$device_id" ]; then
    maestro test --device "$device_id" "$E2E_ROOT/flows/${flow_name}.yaml"
  else
    maestro test "$E2E_ROOT/flows/${flow_name}.yaml"
  fi
}

echo "--- Between-devices (iOS = author, Android = receiver). Assume devices already connected. ---"
if [ "$PLATFORM" = "ios" ] || [ -z "$PLATFORM" ]; then
  echo "Step 1: iOS — create post"
  run_maestro "$APP_ID_IOS" "post" "$DEVICE_ID_IOS"
  echo "Waiting 3s for backend to propagate..."
  sleep 3
fi
if [ "$PLATFORM" = "android" ] || [ -z "$PLATFORM" ]; then
  echo "Step 2: Android — see post"
  run_maestro "$APP_ID_ANDROID" "see_post_on_other_device" "$DEVICE_ID_ANDROID"
fi
if [ "$PLATFORM" = "ios" ] || [ -z "$PLATFORM" ]; then
  echo "Step 3: iOS — add comment"
  run_maestro "$APP_ID_IOS" "comment" "$DEVICE_ID_IOS"
  echo "Waiting 3s for backend to propagate..."
  sleep 3
fi
if [ "$PLATFORM" = "android" ] || [ -z "$PLATFORM" ]; then
  echo "Step 4: Android — see comment"
  run_maestro "$APP_ID_ANDROID" "see_comment_on_other_device" "$DEVICE_ID_ANDROID"
fi
if [ "$PLATFORM" = "ios" ] || [ -z "$PLATFORM" ]; then
  echo "Step 5: iOS — delete comment (US-010)"
  run_maestro "$APP_ID_IOS" "delete_comment" "$DEVICE_ID_IOS"
  echo "Waiting 5s for COMMENT_DELETED to sync to Android..."
  sleep 5
fi
if [ "$PLATFORM" = "android" ] || [ -z "$PLATFORM" ]; then
  echo "Step 6: Android — assert comment gone after sync"
  run_maestro "$APP_ID_ANDROID" "see_comment_deleted_on_other_device" "$DEVICE_ID_ANDROID"
fi
echo "Between-devices test finished."

if [ "$RUN_NOTIFICATIONS" = true ]; then
  echo "--- Notifications (receiver) ---"
  run_maestro "$APP_ID_ANDROID" "notifications" "$DEVICE_ID_ANDROID"
fi

echo "E2E run finished."
