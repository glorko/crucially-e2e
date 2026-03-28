#!/usr/bin/env bash
# Comprehensive MVP E2E test script.
# Covers all user stories in a logical order using two devices (iOS + Android).
# Assumes crux is running (backend + both app instances).
#
# Usage:
#   ./scripts/run-e2e-full.sh [--ios-only|--android-only] [--skip-cross-device]
#
# Prerequisites:
#   - crux running (backend + iOS + Android apps)
#   - Both devices signed in and connected to each other
#   - Maestro installed and on PATH
set -e

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
SKIP_CROSS_DEVICE=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --ios-only) PLATFORM=ios; shift ;;
    --android-only) PLATFORM=android; shift ;;
    --skip-cross-device) SKIP_CROSS_DEVICE=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

TS=$(date +%s)
export MAESTRO_E2E_POST_TEXT="e2e post $TS"
export MAESTRO_E2E_EDITED_POST_TEXT="e2e edited post $TS"
export MAESTRO_E2E_COMMENT_TEXT="e2e comment $TS"
export MAESTRO_E2E_EDITED_COMMENT_TEXT="e2e edited comment $TS"
export MAESTRO_E2E_SUFFIX="$TS"

PASSED=0
FAILED=0
SKIPPED=0

run_ios() {
  local flow=$1 label=$2
  if [ "$PLATFORM" = "android" ]; then
    echo "  SKIP (ios-only): $label"
    ((SKIPPED++))
    return 0
  fi
  echo "  RUN [iOS]: $label"
  export MAESTRO_APP_ID="$APP_ID_IOS"
  if maestro test --device "$DEVICE_ID_IOS" "$E2E_ROOT/flows/${flow}.yaml"; then
    echo "  PASS: $label"
    ((PASSED++))
  else
    echo "  FAIL: $label"
    ((FAILED++))
    return 1
  fi
}

run_android() {
  local flow=$1 label=$2
  if [ "$PLATFORM" = "ios" ]; then
    echo "  SKIP (android-only): $label"
    ((SKIPPED++))
    return 0
  fi
  echo "  RUN [Android]: $label"
  export MAESTRO_APP_ID="$APP_ID_ANDROID"
  if maestro test --device "$DEVICE_ID_ANDROID" "$E2E_ROOT/flows/${flow}.yaml"; then
    echo "  PASS: $label"
    ((PASSED++))
  else
    echo "  FAIL: $label"
    ((FAILED++))
    return 1
  fi
}

echo "=========================================="
echo "  Crucially MVP — Comprehensive E2E Run"
echo "  Timestamp: $TS"
echo "=========================================="
echo ""

# ──────────────────────────────────────────────
# Phase 1: Settings & Configuration (US-019, US-020, US-025, US-021, US-017, US-002)
# ──────────────────────────────────────────────
echo "── Phase 1: Settings ──"

run_ios   "settings_sound_toggle"  "US-025 Sound toggle (iOS)" || true
run_android "settings_sound_toggle" "US-025 Sound toggle (Android)" || true
run_ios   "settings_app_lock"      "US-019 App lock (iOS)" || true
run_android "settings_app_lock"    "US-019 App lock (Android)" || true
run_ios   "app_lock"               "US-019 App lock (ensure_feed) (iOS)" || true
run_android "app_lock"             "US-019 App lock (ensure_feed) (Android)" || true
run_ios   "settings_legal"         "US-020 ToS/Privacy links (iOS)" || true
run_android "settings_legal"       "US-020 ToS/Privacy links (Android)" || true
run_ios   "storage_warning"        "US-017 Storage monitoring (iOS)" || true
run_android "storage_warning"      "US-017 Storage monitoring (Android)" || true
run_ios   "session_invalid"        "US-002 Session valid (iOS)" || true
run_android "session_invalid"      "US-002 Session valid (Android)" || true

echo ""

# ──────────────────────────────────────────────
# Phase 2: Profile (US-001)
# ──────────────────────────────────────────────
echo "── Phase 2: Profile ──"

run_ios   "profile_edit"           "US-001 Edit display name (iOS)" || true
run_android "profile_edit"         "US-001 Edit display name (Android)" || true
run_ios   "profile_avatar"         "US-001 Profile avatar (iOS)" || true
run_android "profile_avatar"       "US-001 Profile avatar (Android)" || true

echo ""

# ──────────────────────────────────────────────
# Phase 3: Updates & Navigation (US-008, US-022)
# ──────────────────────────────────────────────
echo "── Phase 3: Navigation ──"

run_ios   "updates_screen"         "US-008 Updates screen (iOS)" || true
run_android "updates_screen"       "US-008 Updates screen (Android)" || true

echo ""

# ──────────────────────────────────────────────
# Phase 4: Connections (US-003, US-023)
# ──────────────────────────────────────────────
echo "── Phase 4: Connections ──"

run_ios   "connection_activity"    "US-023 Connection activity (iOS)" || true
run_android "connection_activity"  "US-023 Connection activity (Android)" || true

echo ""

# ──────────────────────────────────────────────
# Phase 5: Post lifecycle — single device (US-004, US-005, US-022, US-024, US-020)
# ──────────────────────────────────────────────
echo "── Phase 5: Post lifecycle (single device) ──"

run_ios   "tos_acceptance"   "US-020 ToS acceptance gate (iOS)" || true
run_android "tos_acceptance" "US-020 ToS acceptance gate (Android)" || true

# Content posting integration: create post and verify it appears on feed (same device)
run_ios   "content_posting"  "Content posting integration (iOS)" || true
run_android "content_posting" "Content posting integration (Android)" || true

run_ios "post"              "Create post (iOS)" || true
run_ios "open_post_detail"  "US-022 Post detail (iOS)" || true
run_ios "edit_post"         "US-005 Edit post (iOS)" || true
# After edit, feed still shows original text
run_ios "delete_post"       "US-004 Delete post (iOS)" || true

# Fresh post for Android
export MAESTRO_E2E_POST_TEXT="e2e android post $TS"
export MAESTRO_E2E_EDITED_POST_TEXT="e2e android edited $TS"

run_android "post"              "Create post (Android)" || true
run_android "open_post_detail"  "US-022 Post detail (Android)" || true
run_android "edit_post"         "US-005 Edit post (Android)" || true
run_android "delete_post"       "US-004 Delete post (Android)" || true

echo ""

# ──────────────────────────────────────────────
# Phase 6: Comment lifecycle — single device (US-009, US-010)
# ──────────────────────────────────────────────
echo "── Phase 6: Comment lifecycle (single device) ──"

export MAESTRO_E2E_POST_TEXT="e2e comment host $TS"
export MAESTRO_E2E_COMMENT_TEXT="e2e comment $TS"
export MAESTRO_E2E_EDITED_COMMENT_TEXT="e2e edited comment $TS"

run_ios "post"              "Create post for comments (iOS)" || true
run_ios "comment"           "Add comment (iOS)" || true
run_ios "edit_comment"      "US-009 Edit comment (iOS)" || true
# After edit, comment text changed to edited version
export MAESTRO_E2E_COMMENT_TEXT="$MAESTRO_E2E_EDITED_COMMENT_TEXT"
run_ios "delete_comment"    "US-010 Delete comment (iOS)" || true

echo ""

# ──────────────────────────────────────────────
# Phase 7: Media posting UI (US-024, US-016)
# ──────────────────────────────────────────────
echo "── Phase 7: Media posting UI ──"

export MAESTRO_E2E_POST_TEXT="e2e media $TS"

run_ios   "post_with_media"  "US-024 Media attachment UI (iOS)" || true
run_android "post_with_media" "US-024 Media attachment UI (Android)" || true
run_ios   "media_request"    "US-016 Media request placeholder (iOS)" || true
run_android "media_request"  "US-016 Media request placeholder (Android)" || true

echo ""

# ──────────────────────────────────────────────
# Phase 8: Cross-device sync (US-004, US-005, US-007, US-010)
# ──────────────────────────────────────────────
if [ "$SKIP_CROSS_DEVICE" = false ] && [ -z "$PLATFORM" ]; then
  echo "── Phase 8: Cross-device sync ──"

  export MAESTRO_E2E_POST_TEXT="e2e cross $TS"
  export MAESTRO_E2E_COMMENT_TEXT="e2e cross comment $TS"

  echo "  Step 1: iOS creates post"
  run_ios "post" "Cross-device: Create post (iOS)" || true
  sleep 3

  echo "  Step 2: Android sees post (content posting integration receive)"
  run_android "content_posting_receive" "Cross-device: Content posting receive (Android)" || true
  run_android "see_post_on_other_device" "Cross-device: See post (Android)" || true

  echo "  Step 3: iOS edits post"
  run_ios "edit_post" "Cross-device: Edit post (iOS)" || true
  sleep 3

  echo "  Step 4: Android sees edited post"
  export MAESTRO_E2E_POST_TEXT="$MAESTRO_E2E_EDITED_POST_TEXT"
  run_android "see_post_edited_on_other_device" "Cross-device: See edited post (Android)" || true

  echo "  Step 5: iOS adds comment"
  run_ios "comment" "Cross-device: Add comment (iOS)" || true
  sleep 3

  echo "  Step 6: Android sees comment"
  run_android "see_comment_on_other_device" "Cross-device: See comment (Android)" || true

  echo "  Step 7: iOS deletes comment"
  run_ios "delete_comment" "Cross-device: Delete comment (iOS)" || true
  sleep 5

  echo "  Step 8: Android sees comment deleted"
  run_android "see_comment_deleted_on_other_device" "Cross-device: Comment gone (Android)" || true

  echo ""
fi

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────
echo "=========================================="
echo "  Results: $PASSED passed, $FAILED failed, $SKIPPED skipped"
echo "=========================================="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
