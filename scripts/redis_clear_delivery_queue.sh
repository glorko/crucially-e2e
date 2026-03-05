#!/usr/bin/env bash
# Clear the entire delivery queue in Redis (all users). Leaves event_store:* intact so
# hash-based recovery still works. Use for local E2E: no user_id or other params needed.
#
# Uses redis-cli inside the Redis Docker container (same as crux config: crucially-redis).
# Override container: REDIS_CONTAINER=my-redis ./redis_clear_delivery_queue.sh
#
# Usage: ./redis_clear_delivery_queue.sh
#
# After this, PullInbox(nil) returns empty for everyone; clients use recovery (Sync now).

set -e

REDIS_CONTAINER="${REDIS_CONTAINER:-crucially-redis}"
R="docker exec $REDIS_CONTAINER redis-cli"

count=0
for pattern in "delivery:*" "deliveries:user:*" "event:*" "event:metadata:*"; do
  keys=$($R KEYS "$pattern" 2>/dev/null || true)
  if [[ -n "$keys" ]]; then
    n=$(echo "$keys" | wc -w | tr -d ' ')
    $R DEL $keys >/dev/null
    ((count+=n)) || true
  fi
done

echo "Cleared $count delivery-queue key(s). Event store untouched; use Sync now to recover."
