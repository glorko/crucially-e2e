#!/usr/bin/env bash
# Run Maestro E2E tests with crux (backend + 2 app instances).
# Usage:
#   From crucially-e2e: ./scripts/run-e2e.sh [--no-crux] [--ios-only|--android-only] [--flow NAME] [--with-notifications] [--between-devices]
#   With --no-crux: assume crux is already running; only run Maestro.
#   With --flow NAME: run only the specified flow (e.g. post, comment, connection, add_connection_paste) for quick iteration.
#   With --with-notifications: also run notifications flow (receiver device; requires two devices: sender posts first).
#   With --between-devices: two-device test (A posts, B sees). Assumes devices already connected. Runs post on iOS (A),
#     see_post_on_other_device + open_post on Android (B).
set -e

# Ensure Maestro is on PATH (default install: ~/.maestro/bin)
if [ -d "${HOME}/.maestro/bin" ]; then
  export PATH="${HOME}/.maestro/bin:${PATH}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E2E_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CRUCIALLY_ROOT="${CRUCIALLY_ROOT:-$(cd "$E2E_ROOT/.." && pwd)}"
# Prefer E2E config (playground format: backend + iOS + Android) if present
if [ -f "${CRUCIALLY_ROOT}/config.e2e.yaml" ]; then
  CONFIG_YAML="${CRUCIALLY_ROOT}/config.e2e.yaml"
else
  CONFIG_YAML="${CRUCIALLY_ROOT}/config.yaml"
fi

APP_ID_IOS="${MAESTRO_APP_ID_IOS:-app.crucially.ios}"
APP_ID_ANDROID="${MAESTRO_APP_ID_ANDROID:-app.crucially.android}"
# Device IDs: default to crux config (app1 = iOS, app2 = Android). Override with MAESTRO_DEVICE_ID_IOS / MAESTRO_DEVICE_ID_ANDROID.
DEVICE_ID_IOS="${MAESTRO_DEVICE_ID_IOS:-90266925-B62F-4741-A89E-EF11BFA0CC57}"
DEVICE_ID_ANDROID="${MAESTRO_DEVICE_ID_ANDROID:-emulator-5556}"

RUN_CRUX=true
PLATFORM=""
RUN_NOTIFICATIONS=false
RUN_BETWEEN_DEVICES=false
FLOW_NAME=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --no-crux) RUN_CRUX=false; shift ;;
    --ios-only) PLATFORM=ios; shift ;;
    --android-only) PLATFORM=android; shift ;;
    --flow) FLOW_NAME="${2:-}"; shift 2 ;;
    --with-notifications) RUN_NOTIFICATIONS=true; shift ;;
    --between-devices) RUN_BETWEEN_DEVICES=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Unique post text for this run (timestamp so we don't match old posts with same text)
export MAESTRO_E2E_POST_TEXT="${MAESTRO_E2E_POST_TEXT:-E2E test post from Maestro $(date +%Y-%m-%d_%H-%M-%S)}"
echo "E2E post text for this run: $MAESTRO_E2E_POST_TEXT"

if [ "$RUN_CRUX" = true ]; then
  echo "Ensure crux is running from $CRUCIALLY_ROOT with config $CONFIG_YAML"
  if [ ! -f "$CONFIG_YAML" ]; then
    echo "Config not found: $CONFIG_YAML. Set CRUCIALLY_ROOT or run from crucially repo."
    exit 1
  fi
  (cd "$CRUCIALLY_ROOT" && crux -c "$CONFIG_YAML") &
  CRUX_PID=$!
  echo "Waiting for backend and apps to be ready (90s for Flutter build + launch)..."
  sleep 90
fi

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

if [ "$RUN_BETWEEN_DEVICES" = true ]; then
  echo "--- Between-devices (iOS creates, Android receives — iOS has no push on simulator). Assume devices already connected. ---"
  echo "Step 1: iOS — create post"
  run_maestro "$APP_ID_IOS" "post" "$DEVICE_ID_IOS"
  echo "Step 2: Android — see post"
  run_maestro "$APP_ID_ANDROID" "see_post_on_other_device" "$DEVICE_ID_ANDROID"
  echo "Step 3: Android — open post (comment section)"
  run_maestro "$APP_ID_ANDROID" "open_post" "$DEVICE_ID_ANDROID"
  echo "Step 4: iOS — add comment"
  run_maestro "$APP_ID_IOS" "comment" "$DEVICE_ID_IOS"
  echo "Step 5: Android — see comment"
  run_maestro "$APP_ID_ANDROID" "see_comment_on_other_device" "$DEVICE_ID_ANDROID"
  echo "Between-devices test finished."
else
  MAIN_FLOWS=(post comment connection open_post see_post_on_other_device)
  if [ -n "$FLOW_NAME" ]; then
    echo "Running single flow: $FLOW_NAME"
    MAIN_FLOWS=("$FLOW_NAME")
  fi
  echo "Running Maestro flows from $E2E_ROOT/flows"

  if [ "$PLATFORM" = "ios" ] || [ -z "$PLATFORM" ]; then
    echo "--- iOS (app1) ---"
    for f in "${MAIN_FLOWS[@]}"; do
      run_maestro "$APP_ID_IOS" "$f" "$DEVICE_ID_IOS"
    done
  fi

  if [ "$PLATFORM" = "android" ] || [ -z "$PLATFORM" ]; then
    echo "--- Android (app2) ---"
    for f in "${MAIN_FLOWS[@]}"; do
      run_maestro "$APP_ID_ANDROID" "$f" "$DEVICE_ID_ANDROID"
    done
  fi
fi

# Notifications flow: run on receiver device; requires two devices (sender posts while receiver in background)
if [ "$RUN_NOTIFICATIONS" = true ]; then
  echo "--- Notifications (receiver; ensure sender already ran post while this device was in background) ---"
  run_maestro "$APP_ID_ANDROID" "notifications" "$DEVICE_ID_ANDROID"
fi

if [ "$RUN_CRUX" = true ] && [ -n "${CRUX_PID:-}" ]; then
  kill $CRUX_PID 2>/dev/null || true
fi

echo "E2E run finished."
