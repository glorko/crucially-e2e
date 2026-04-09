# Crucially E2E — Maestro integration tests

Maestro-based end-to-end tests for the Crucially Flutter app. Designed to run with **crux** (backend + iOS + Android instances) and to be **reusable** for other apps.

## E2E requirements

Flows and coverage are defined by this README and the PRD §5.1 (Posting, Comments, Connections, Notifications, Feed/Updates). New flows should use **ensure_feed** when they need to be on Feed (handles login screen when visible), use **app semantics** where available and **visible text** otherwise, and **reset** via script or HTTP when needed.

## Prerequisites

- **Maestro**: Install the CLI ([docs](https://maestro.mobile.dev/getting-started/installation)).
  ```bash
  curl -Ls "https://get.maestro.mobile.dev" | bash
  maestro --version
  ```
- **Crux**: Backend and two app instances (iOS simulator + Android emulator) are started via crux. Use the workspace root `config-local.yaml` (`crux -c config-local.yaml`). Default `config.yaml` is staging-mobile-only. A commented reference copy is [crucially-metadata/docs/crux_workspace_config.yaml](../crucially-metadata/docs/crux_workspace_config.yaml).
- **Test accounts**: Use dedicated Firebase test accounts (Google on Android, Apple on iOS). Flows **handle auth when needed**: if the login screen is visible, they tap "Continue with Google" or "Continue with Apple" and wait for Feed. System OAuth dialogs may still require a one-time manual sign-in on the device; after that, sessions are reused.
- **Backend**: Postgres, Redis, and (for push) FCM configured. Optional: test reset endpoint or script for clearing test data (see [Reset](#reset-to-default-state)).

## Running tests

### 1. Start crux (from Crucially repo)

```bash
cd /path/to/crucially
crux -c config-local.yaml
```

This starts the backend and two Flutter apps (app1 = iOS, app2 = Android). Leave it running.

### 2. Run Maestro (from this repo)

**Maestro does not launch or restart the app.** Flows assume the app is already running (started by crux). This keeps crux terminals connected and avoids restarting the app.

```bash
cd crucially-e2e

# iOS
export MAESTRO_APP_ID=app.crucially.ios
maestro test flows/post.yaml
maestro test flows/comment.yaml
maestro test flows/connection.yaml

# Android (switch device or use --device)
export MAESTRO_APP_ID=app.crucially.android
maestro test flows/post.yaml
maestro test flows/comment.yaml
maestro test flows/connection.yaml
```

### 3. Using the run script

```bash
./scripts/run-e2e.sh                    # Between-devices post/comment/delete (iOS + Android; crux must already be running)
./scripts/run-e2e.sh --ios-only
./scripts/run-e2e.sh --android-only
./scripts/run-e2e.sh --with-notifications  # Also run notifications flow (Android as receiver; two devices required)
./scripts/run-e2e.sh --delayed-delivery   # Android offline → iOS post → clear Redis → Android Sync → assert recovered post
./scripts/run-e2e.sh --comment-edit-sync   # After B sees comment: iOS edit_comment → B see_comment_edited → delete uses edited text
./scripts/run-e2e.sh --chat                # After main run: iOS chat_dm_send → Android chat_dm_receive (needs chat list row)
```

- **Env**: `CRUCIALLY_ROOT` — path to Crucially repo (default: parent of this repo). `E2E_RESET_SCRIPT` — path to `crucially-backend/scripts/reset_test_data.sh` to run before tests. `E2E_RESET_URL` — optional HTTP reset endpoint. **`MAESTRO_E2E_COMMENT_DELETE_TEXT`** — text `delete_comment` / `see_comment_deleted_on_other_device` target (defaults to `MAESTRO_E2E_COMMENT_TEXT`; after `--comment-edit-sync`, the script sets it to the edited string). **`MAESTRO_E2E_EDITED_COMMENT_TEXT`** — used by `edit_comment.yaml` and `see_comment_edited_on_other_device.yaml`. **`MAESTRO_E2E_CHAT_MESSAGE_TEXT`** — DM body for `chat_dm_send` / `chat_dm_receive`.
- **Device IDs**: When both iOS and Android are running, set `MAESTRO_DEVICE_ID_IOS` and `MAESTRO_DEVICE_ID_ANDROID` so each platform’s flows run on the correct device. Get IDs from `flutter devices` (e.g. iPhone 15 Pro UUID, `emulator-5556`). Example: `export MAESTRO_DEVICE_ID_IOS="90266925-B62F-4741-A89E-EF11BFA0CC57" MAESTRO_DEVICE_ID_ANDROID="emulator-5556"`.

## Flows

| Flow | Description |
|------|-------------|
| `post.yaml` | Create a text post from Feed (New Post → type → Post). |
| `comment.yaml` | Add a comment on the E2E post (waits for "E2E test post from Maestro", then comment input → type "E2E comment from Maestro" → send). Run on device B after `see_post_on_other_device.yaml` for comment-sync flow. |
| `connection.yaml` | Open profile drawer → Connections → Add Connection; assert QR/code screen. |
| `open_post.yaml` | Tap the first post in the feed (by E2E post text) and assert comment section is visible. Run after `post.yaml`. |
| `add_connection_paste.yaml` | **Device B**: add connection by pasting A's code. Requires `CONNECTION_CODE` env var (code shown on A's Add Connection screen). Run after A ran `connection.yaml`. |
| `initiate_connection_a_to_b.yaml` | **Device A**: initiate connection from A to B (A adds B by pasting B's code). Requires `CONNECTION_CODE` env var set to B's code. Run after B has displayed its code (`connection.yaml` on B). *Execution so far:* tests run with non-empty DB for simplicity; in future e2e will be tested from an empty database. |
| `see_post_on_other_device.yaml` | **Receiver device**: ensure Feed, then wait for "E2E test post from Maestro" (up to 45s). Run on device B after device A ran `post.yaml`; requires A and B to be connected. |
| `see_comment_on_other_device.yaml` | **Receiver device**: ensure Feed, then wait for "E2E comment from Maestro" (up to 45s). Run on device A after device B ran `comment.yaml`; verifies comment sync to connections. |
| `see_comment_edited_on_other_device.yaml` | **Receiver (e.g. Android)** after author ran `edit_comment.yaml` with `MAESTRO_E2E_EDITED_COMMENT_TEXT`; asserts edited body on feed. |
| `chat_open_list.yaml` | Open Chat tab; assert **Chat** title (empty list or conversations). |
| `chat_dm_send.yaml` / `chat_dm_receive.yaml` | Two-device DM: sender opens `chat_list_first_row`, types `MAESTRO_E2E_CHAT_MESSAGE_TEXT`, sends; receiver opens first row and asserts text. Requires mutual connection and at least one list row. |
| `frozen_slot_paused_assert.yaml` | **Optional**: assert `connection_slot_paused_badge` on Connections. Requires a **data precondition** (e.g. slot subscription `past_due` / frozen slot) — set manually or via DB before running. |
| `transfer_open_from_settings_debug.yaml` | **Debug build only**: Settings → E2E transfer tile → `transfer_instructions_start`. |
| `ensure_feed.yaml` | Subflow: if login screen visible, tap sign-in and wait for Feed; then assert Feed. Used by other flows (app is already running). |
| `android_enable_airplane.yaml` | **Android only**: enable airplane mode. Run before iOS post in delayed-delivery E2E so receiver is offline. |
| `delayed_delivery_recovery.yaml` | **Android**: disable airplane, ensure feed, Settings → Refresh feed, back to Feed, wait for post (env: `MAESTRO_E2E_DELAYED_POST_TEXT`). Run after `android_enable_airplane` → iOS post → `redis_clear_delivery_queue.sh`. |
| `type_text.yaml` | Subflow: type a string character-by-character (env: `TYPEWRITER_TEXT`). Used by post and comment flows so app typewriter/animation works. |
| `notifications.yaml` | **Receiver device**: background app (`pressKey: Home`), wait for "You have new mail", tap notification. Do **not** use `stopApp` (push won't be delivered). Run with `--with-notifications` (Android as receiver). |
| `delayed_delivery_recovery.yaml` | **Receiver device (B)**: after Device A posted and Redis was cleared, open Settings → Refresh feed, then assert the post on Feed (hash-based recovery). See [Delayed delivery recovery](#delayed-delivery-recovery). |

### Two-device posting (A posts, B sees)

**Option 1 — Using the run script (recommended)**

1. Start crux (backend + iOS + Android). Set device IDs if needed:  
   `export MAESTRO_DEVICE_ID_IOS="90266925-B62F-4741-A89E-EF11BFA0CC57" MAESTRO_DEVICE_ID_ANDROID="emulator-5556"`
2. Run the between-devices sequence:  
   `./scripts/run-e2e.sh --between-devices`  
   This runs the **connection** flow on iOS (device A); the Add Connection screen stays open with the code visible.
3. Copy the connection code from device A (the text under the QR code).
4. Set it and re-run:  
   `export CONNECTION_CODE=<code-you-copied>`  
   `./scripts/run-e2e.sh --no-crux --between-devices`  
   This runs **add_connection_paste** on Android (B), **post** on iOS (A), and **see_post_on_other_device** on Android (B).

**Option 2 — Manual flow order**

1. Start crux (backend + iOS + Android).
2. On **device A (e.g. iOS)**: `maestro test --device $MAESTRO_DEVICE_ID_IOS flows/connection.yaml` (shows QR/code; leave screen open).
3. On **device B (e.g. Android)**:  
   `CONNECTION_CODE=<code-from-A> maestro test --device $MAESTRO_DEVICE_ID_ANDROID flows/add_connection_paste.yaml`
4. On **device A**: `maestro test --device $MAESTRO_DEVICE_ID_IOS flows/post.yaml`
5. On **device B**: `maestro test --device $MAESTRO_DEVICE_ID_ANDROID flows/see_post_on_other_device.yaml`
6. Optionally on B: `maestro test flows/open_post.yaml` to open the post and assert comment section.

### Two-device comment sync (A posts, B comments, A sees comment)

To verify that comments sync to connections (post author's connections receive the comment):

1. Complete the two-device posting steps above so device A has posted and device B has seen the post.
2. On **device B**: `maestro test --device $MAESTRO_DEVICE_ID_ANDROID flows/comment.yaml` (adds "E2E comment from Maestro" on the E2E post).
3. On **device A**: bring the app to foreground (so PullInbox runs), then run:  
   `maestro test --device $MAESTRO_DEVICE_ID_IOS flows/see_comment_on_other_device.yaml`  
   This waits for "E2E comment from Maestro" to appear (up to 45s) and asserts it is visible.

Flow order: **Device A** `post.yaml` → **Device B** `see_post_on_other_device.yaml` → **Device B** `comment.yaml` → **Device A** `see_comment_on_other_device.yaml`.

### Two-device comment **edit** sync (optional)

Use `./scripts/run-e2e.sh --comment-edit-sync` so that after Android sees the new comment, iOS runs `edit_comment.yaml`, Android runs `see_comment_edited_on_other_device.yaml`, and the delete step targets **`MAESTRO_E2E_COMMENT_DELETE_TEXT`** (automatically aligned with the edited text).

Manual order: same posting/comment steps as above, then **iOS** `edit_comment.yaml` (set `MAESTRO_E2E_EDITED_COMMENT_TEXT`) → **Android** `see_comment_edited_on_other_device.yaml` → export `MAESTRO_E2E_COMMENT_DELETE_TEXT` to the same edited value → **iOS** `delete_comment.yaml` → **Android** `see_comment_deleted_on_other_device.yaml`.

### Chat DM smoke (two devices)

Prerequisites: mutual connection; Chat list shows at least one row (pending DM or existing thread). Run `./scripts/run-e2e.sh --chat` after the default between-devices sequence, or manually: **iOS** `chat_dm_send.yaml` → wait a few seconds → **Android** `chat_dm_receive.yaml` with the same `MAESTRO_E2E_CHAT_MESSAGE_TEXT`.

### Frozen (“Paused”) slots

There is no automated API reset in this repo for freezing a slot. Before `frozen_slot_paused_assert.yaml`, prepare data so at least one occupied slot is billing-frozen (e.g. SQL / ops on `slot_subscriptions` for a test user). Then open Connections and run the flow.

### Device transfer (debug)

`settings_transfer_test_flow` and `transfer_open_from_settings_debug.yaml` work only in **debug** Flutter builds. They open `TransferFlowScreen` as a new device so Maestro can assert `transfer_instructions_start` / `transfer_confirm_continue` on the appropriate steps.

### Delayed delivery recovery

Verifies hash-based recovery (US-012): **Device B (Android) is offline** so it never receives the post via real-time delivery; we clear the Redis delivery queue; then Device B goes online and taps **Settings → Refresh feed** and receives the post from the backend event store.

**Prerequisites**: Backend wired with Redis event store (see `crucially-backend/internal/api/grpc/README.md`). Crux running (backend + iOS + Android). Two users connected. **Order matters**: Android must be offline *before* iOS posts, otherwise normal sync delivers the post in milliseconds and clearing Redis is pointless.

**One-command run** (recommended):

```bash
./scripts/run-e2e.sh --delayed-delivery
```

This runs: Android airplane on → iOS post (unique text) → clear Redis delivery queue → Android airplane off + open app + Settings → Refresh feed → assert recovered post.

**Manual steps** (same order):

1. **Android**: enable airplane mode (so receiver is offline). With Maestro:  
   `maestro test --device $MAESTRO_DEVICE_ID_ANDROID -e MAESTRO_APP_ID=app.crucially.android flows/android_enable_airplane.yaml`
2. **iOS**: post with a unique text, e.g.  
   `MAESTRO_E2E_POST_TEXT="e2e delayed $(date +%s)" maestro test --device $MAESTRO_DEVICE_ID_IOS -e MAESTRO_APP_ID=app.crucially.ios -e MAESTRO_E2E_POST_TEXT="…" flows/post.yaml`
3. Clear the delivery queue (event store is left intact):  
   `./scripts/redis_clear_delivery_queue.sh`  
   (Uses `docker exec crucially-redis redis-cli`; set `REDIS_CONTAINER` if your Redis container has another name.)
4. **Android**: run recovery flow (turns airplane off, ensure feed, Settings → Refresh feed, assert post):  
   `MAESTRO_E2E_DELAYED_POST_TEXT="<same as step 2>" maestro test --device $MAESTRO_DEVICE_ID_ANDROID flows/delayed_delivery_recovery.yaml`

**UI**: Use **Settings → Refresh feed** to trigger sync with recovery (no app bar button).

**Scripts** (redis-cli via Docker; container from crux: `crucially-redis`, override with `REDIS_CONTAINER`):
- `scripts/redis_clear_delivery_queue.sh` — clears the whole delivery queue (no params).
- `scripts/redis_clear_deliveries_for_user.sh <user_id>` — clears deliveries for one user. Requires `jq` or `USE_PYTHON=1`.

### Initiate connection A→B (A adds B)

This flow runs on **device A** and adds **device B** as a connection by pasting B's code.

1. On **device B**: run `connection.yaml` so B's Add Connection screen shows the code; copy the code from B's screen.
2. Set `CONNECTION_CODE=<code-from-B>` and on **device A** run:  
   `maestro test --device $MAESTRO_DEVICE_ID_IOS flows/initiate_connection_a_to_b.yaml` (or Android device id if A is Android).

**Execution so far:** e2e tests are run with a non-empty database for simplicity. In future, the full e2e flow will be tested from an empty database; this flow will be part of that sequence (B shows code → A pastes B's code → A and B connected).

## Notifications

Notifications are shown only when the app is in the **background**. In Maestro:

- Use **`pressKey: Home`** to send the app to background (do **not** use `stopApp`).
- On the other device, create a post (or trigger the action that sends push).
- On the receiver device, wait for the notification (e.g. "You have new mail") then tap it, or bring the app to foreground and assert in Updates/Feed.

## Reset to default state

- **Option A (recommended)**: Run the backend reset script before the suite. From the Crucially repo, `scripts/reset_test_data.sh` truncates `users` and `connections`; optionally set `REDIS_E2E_FLUSH=1` to flush Redis. The E2E run script can call it:
  ```bash
  export E2E_RESET_SCRIPT="../crucially/crucially-backend/scripts/reset_test_data.sh"
  ./scripts/run-e2e.sh --no-crux
  ```
  Or run the script manually before starting tests.
- **Option B**: Backend exposes a test-only HTTP reset; set `E2E_RESET_URL` and the run script will `POST` to it.
- **Option C**: Maestro/app clear state; then re-auth is required.

## Config

- `config/maestro.yaml` — App IDs and backend URL (env overrides: `MAESTRO_APP_ID_IOS`, `MAESTRO_APP_ID_ANDROID`).
- `config/crux-config.example.yaml` — Pointer to Crux at the workspace root: default `config.yaml` (staging apps), full stack `config-local.yaml`. See [crucially-metadata/docs/crux_workspace_config.yaml](../crucially-metadata/docs/crux_workspace_config.yaml).

## Reusing this setup for other apps

1. Copy this repo (or `flows/` and `scripts/`).
2. Set app IDs and backend URL in env or `config/maestro.yaml`.
3. Adapt flows to your app: same pattern (text/semantic IDs for Feed, Post, Connections, etc.).
4. Use the same **notification pattern**: background with `pressKey: Home`, no `stopApp`.
5. Use the same **reset pattern**: backend reset endpoint or script, or clear app data.

## App semantics (Crucially mobile)

The Crucially app exposes test IDs for Maestro where needed:

- `app_bar_new_post` — Create post button in app bar.
- `settings_refresh_feed` — Settings: "Refresh feed" tile (triggers sync with hash-based recovery).
- `app_bar_profile_drawer` — Profile/drawer button in app bar.
- `comment_submit` — Send comment button.
- `login_sign_in_button` — Sign-in button on login screen (Continue with Google / Apple).
- `nav_chat`, `nav_connections`, `nav_settings` — Bottom navigation (with `nav_feed`, `nav_updates`).
- `chat_fab_new_group` — Chat list FAB (new group).
- `chat_list_first_row` / `chat_list_row_<n>` — Chat list rows.
- `chat_message_input`, `chat_send_button`, `chat_attach_image_button` — Thread composer; `chat_paused_banner_dismiss` — disconnect banner dismiss.
- `connections_tier_layer_chips` — Horizontal tier chip list; `connections_unlock_next_layer_button` — unlock next layer CTA.
- `billing_unlock_sheet_continue` — Unlock sheet “Continue to payment”.
- `staging_checkout_screen_title`, `staging_checkout_pay_button` — Pre–store staging checkout screen (no Maestro payment flows in this repo; IDs reserved for future staging IAP tests).
- `connection_slot_paused_badge` / `connection_slot_paused_badge_<slotIndex>` — Frozen slot “Paused” chip (tier grid / legacy staggered grid).
- `settings_transfer_test_flow` — Debug-only Settings entry to open transfer flow (new device).
- `transfer_instructions_start`, `transfer_confirm_continue`, `transfer_confirm_cancel` — Transfer flow primary actions.

Flows also use visible text (e.g. "Feed", "Post", "What's on your mind?", "Write a comment...") for stability across i18n when IDs are not required.

## Troubleshooting

- **Maestro can't find element**: Ensure the app is built and launched (e.g. via crux). Use `maestro studio` to inspect the running app and adjust selectors.
- **Two devices**: Run crux so both iOS and Android apps are running. To run Maestro on a specific device, set `MAESTRO_DEVICE_ID_IOS` or `MAESTRO_DEVICE_ID_ANDROID` (e.g. from `flutter devices` or `xcrun simctl list`).
- **Reset script fails**: Ensure Postgres is running and `DATABASE_URL` (or `PGHOST`, `PGPORT`, etc.) matches your backend. Run migrations first.
