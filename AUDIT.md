# Crucially E2E — Audit & Improvement Log (2026-06)

Full audit of the Maestro flow suite and run scripts. This PR lands one safe,
self-contained fix (remove the baked-in personal device UDID); the **headline
problem is that the suite has silently rotted since the May app redesign** and
needs a Maestro-verified rewrite, catalogued below.

---

## ✅ Implemented in this PR

- **Removed the hardcoded personal iOS simulator UDID**
  (`90266925-…CC57`) from `scripts/run-e2e.sh` and `scripts/run-e2e-full.sh`.
  It was a specific contributor's device — useless to everyone else and a small
  PII leak. Both scripts now require `MAESTRO_DEVICE_ID_IOS` and fail fast with a
  clear message (Android keeps the standard `emulator-5554` default). *(prior H11)*

---

## 🔴 The suite is broken — needs a Maestro-verified rewrite

No CI runs these flows, so they rotted unnoticed for 6+ weeks after the redesign
(PR #184). The selectors below were verified against `crucially-mobile/lib`:

- **17 flows tap `app_bar_new_post`** which the redesign removed → use
  `nav_center_action` (and replace the `composer closed` waits on
  `app_bar_new_post`). *(`flows/post.yaml:9` + 16 others)*
- **12 flows tap `nav_settings`** (removed) → `header_open_settings`, ideally via
  one `open_settings.yaml` subflow. *(`flows/profile_edit.yaml:8` + 11 others)*
- **3 connection flows navigate via `app_bar_profile_drawer` / a `ProfileDrawer`
  that is now dead code** → navigate via `nav_connections` and the current
  `_buildMyCodeTab`/`_buildAddSomeoneTab` structure. *(`flows/connection.yaml:13`)*
- **6 flows assert literal text `Connections`** which the redesign renamed to
  **`Crucial People`** → prefer semantics IDs over display text.
  *(`flows/connection_activity.yaml:12`)*
- **`add_connection_paste.yaml`** depends on removed texts `Paste code here` /
  `My Connections`; **`unlink_connection.yaml`** taps a nonexistent `✕` then
  cancels (US-003 unlink is never actually exercised);
  **`transfer_open_from_settings_debug.yaml`** targets a removed debug entry;
  **`notifications.yaml`** waits for push text `You have new mail` that exists in
  neither backend nor app; **`updates_with_entries.yaml`** waits on an anchored
  `ago` regex that can't match `{count}m ago`; **`profile_edit.yaml`** waits for
  `Edit Display Name` (now `Edit display name`).

### Process gap (root cause)
- **No CI / scheduled run** (`README.md:54`). Add a cheap static job that
  yaml-lints flows **and cross-greps every `id:`/critical text in `flows/`
  against `crucially-mobile/lib` semantics IDs**, so the suite can't silently rot
  again. Then a smoke tier on a device/emulator in CI.

---

## 🟡 Structure, duplication & flakiness (catalogued)

- **Device/app-id resolution duplicated** across `run-e2e.sh` and
  `run-e2e-full.sh` → extract `scripts/lib/common.sh` (fail-fast on unset device).
- **Composer / receiver-assert / settings-refresh sequences duplicated across 14
  flows** → parameterized subflows (`create_post.yaml`, `expect_text_on_feed.yaml`,
  `refresh_feed_via_settings.yaml`) using Maestro `runFlow` env. *(`content_posting.yaml:22`)*
- **Every flow re-declares `appId`** and most `runFlow ensure_feed` (prior D5);
  `app_loads_smoke.yaml` uses `${MAESTRO_APP_ID_ANDROID}` while 46 others use
  `${MAESTRO_APP_ID}`.
- **`ensure_feed` can't recover from pushed routes** → flows are order-dependent
  on each other's exit state; add platform-conditional recovery (Android back ×2 /
  iOS left-edge swipe). *(`ensure_feed.yaml:13`)*
- **Android-only `back`/`pressKey: Back`** used in flows `run-e2e-full.sh` executes
  on iOS → platform-conditional `runFlow` blocks. *(`post_with_media.yaml:34`)*
- **6 placeholder flows assert nothing** but are reported as user-story coverage
  (`session_invalid.yaml` et al) → relabel as `smoke_*` / drop the `US-` prefixes.
- **`config/maestro.yaml` is dead config** (never loaded; env names don't match the
  scripts). Promote to a real workspace config or delete.
- **`run_smoke_android_staging.sh` has no device targeting** → accept
  `ANDROID_SERIAL`/`MAESTRO_DEVICE_ID_ANDROID`, pass `-s`/`--device`.
- **Hardcoded `sleep 2/3/5`** across `run-e2e.sh` (prior M11) → `extendedWaitUntil`;
  **test-data reset silent-fails with `|| true`** (prior M12) → fail loudly.
- **`--with-notifications` never backgrounds the receiver before the sender posts**
  → split background+wait like `delayed_delivery_recovery_1/_2`. *(`run-e2e.sh:171`)*
- **README is stale** — recommends `--between-devices`/`--no-crux` flags the script
  doesn't implement, a duplicate flow-table row, a false `type_text` claim.

## Coverage gaps
- Chat epic (US-026–041, 045) has only 3 smoke flows; **billing and offline-outbox
  have none**. Send/receive flows depend on a pre-existing thread (untestable from a
  fresh DB) — add DM-create / group-create flows first. *(`README.md:234`)*

---

*Catalogue generated from a multi-agent audit; selectors cross-checked against
`crucially-mobile/lib`. The broken-flow rewrites are deferred because they need
Maestro Studio verification against running apps — not landable blind.*
