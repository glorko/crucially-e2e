#!/usr/bin/env bash
# Clear all pending deliveries for a recipient user from Redis.
# Used by E2E to simulate "delayed delivery" (queue expired): after this script,
# PullInbox(nil) for that user returns empty and the client must use hash-based recovery.
#
# Uses redis-cli inside the Redis Docker container (same as crux config: crucially-redis).
# Override container: REDIS_CONTAINER=my-redis ./redis_clear_deliveries_for_user.sh <user_id>
#
# Usage: ./redis_clear_deliveries_for_user.sh <user_id>
#
# Requires: docker, jq (or set USE_PYTHON=1 to use Python for JSON parsing)

set -e

USER_ID="${1:?Usage: $0 <user_id>}"
REDIS_CONTAINER="${REDIS_CONTAINER:-crucially-redis}"
R="docker exec $REDIS_CONTAINER redis-cli"

USER_SET_KEY="deliveries:user:${USER_ID}"

# Get all delivery IDs for this user
delivery_ids=$($R SMEMBERS "$USER_SET_KEY")
if [[ -z "$delivery_ids" ]]; then
  echo "No deliveries for user $USER_ID"
  exit 0
fi

count=0
while IFS= read -r delivery_id; do
  [[ -z "$delivery_id" ]] && continue
  delivery_key="delivery:${delivery_id}"
  raw=$($R GET "$delivery_key")
  if [[ -z "$raw" ]]; then
    $R SREM "$USER_SET_KEY" "$delivery_id" >/dev/null
    continue
  fi
  if [[ "${USE_PYTHON:-0}" == "1" ]]; then
    event_id=$(echo "$raw" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('EventID',''))")
  else
    event_id=$(echo "$raw" | jq -r '.EventID // empty')
  fi
  if [[ -n "$event_id" ]]; then
    $R DEL "event:${event_id}" "event:metadata:${event_id}" >/dev/null
  fi
  $R DEL "$delivery_key" >/dev/null
  $R SREM "$USER_SET_KEY" "$delivery_id" >/dev/null
  ((count++)) || true
done <<< "$delivery_ids"

echo "Cleared $count delivery(ies) for user $USER_ID"
