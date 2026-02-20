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
- **Crux**: Backend and two app instances (iOS simulator + Android emulator) are started via crux. See the main Crucially repo `config.yaml`.
- **Test accounts**: Use dedicated Firebase test accounts (Google on Android, Apple on iOS). Flows **handle auth when needed**: if the login screen is visible, they tap "Continue with Google" or "Continue with Apple" and wait for Feed. System OAuth dialogs may still require a one-time manual sign-in on the device; after that, sessions are reused.
- **Backend**: Postgres, Redis, and (for push) FCM configured. Optional: test reset endpoint or script for clearing test data (see [Reset](#reset-to-default-state)).

## Running tests

### 1. Start crux (from Crucially repo)

```bash
cd /path/to/crucially
crux
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
./scripts/run-e2e.sh                    # Runs crux then Maestro (iOS + Android)
./scripts/run-e2e.sh --no-crux         # Only Maestro (crux already running)
./scripts/run-e2e.sh --ios-only
./scripts/run-e2e.sh --android-only
./scripts/run-e2e.sh --with-notifications  # Also run notifications flow (Android as receiver; two devices required)
./scripts/run-e2e.sh --between-devices     # Two-device test: A shows code, B pastes, A posts, B sees post
./scripts/run-e2e.sh --no-crux --flow post # Run only the post flow (for quick iteration)
```

- **Env**: `CRUCIALLY_ROOT` — path to Crucially repo (default: parent of this repo). `E2E_RESET_SCRIPT` — path to `crucially-backend/scripts/reset_test_data.sh` to run before tests. `E2E_RESET_URL` — optional HTTP reset endpoint.
- **Device IDs**: When both iOS and Android are running, set `MAESTRO_DEVICE_ID_IOS` and `MAESTRO_DEVICE_ID_ANDROID` so each platform’s flows run on the correct device. Get IDs from `flutter devices` (e.g. iPhone 15 Pro UUID, `emulator-5556`). Example: `export MAESTRO_DEVICE_ID_IOS="90266925-B62F-4741-A89E-EF11BFA0CC57" MAESTRO_DEVICE_ID_ANDROID="emulator-5556"`.

## Flows

| Flow | Description |
|------|-------------|
| `post.yaml` | Create a text post from Feed (New Post → type → Post). |
| `comment.yaml` | Add a comment to the first post in the feed (Write a comment… → type → send). |
| `connection.yaml` | Open profile drawer → Connections → Add Connection; assert QR/code screen. |
| `open_post.yaml` | Tap the first post in the feed (by E2E post text) and assert comment section is visible. Run after `post.yaml`. |
| `add_connection_paste.yaml` | **Device B**: add connection by pasting A's code. Requires `CONNECTION_CODE` env var (code shown on A's Add Connection screen). Run after A ran `connection.yaml`. |
| `see_post_on_other_device.yaml` | **Receiver device**: ensure Feed, then wait for "E2E test post from Maestro" (up to 45s). Run on device B after device A ran `post.yaml`; requires A and B to be connected. |
| `ensure_feed.yaml` | Subflow: if login screen visible, tap sign-in and wait for Feed; then assert Feed. Used by other flows (app is already running). |
| `type_text.yaml` | Subflow: type a string character-by-character (env: `TYPEWRITER_TEXT`). Used by post and comment flows so app typewriter/animation works. |
| `notifications.yaml` | **Receiver device**: background app (`pressKey: Home`), wait for "You have new mail", tap notification. Do **not** use `stopApp` (push won’t be delivered). Run with `--with-notifications` (Android as receiver). |

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
- `config/crux-config.example.yaml` — Example crux config; copy to the Crucially repo as `config.yaml` or `config.e2e.yaml`.

## Reusing this setup for other apps

1. Copy this repo (or `flows/` and `scripts/`).
2. Set app IDs and backend URL in env or `config/maestro.yaml`.
3. Adapt flows to your app: same pattern (text/semantic IDs for Feed, Post, Connections, etc.).
4. Use the same **notification pattern**: background with `pressKey: Home`, no `stopApp`.
5. Use the same **reset pattern**: backend reset endpoint or script, or clear app data.

## App semantics (Crucially mobile)

The Crucially app exposes test IDs for Maestro where needed:

- `app_bar_new_post` — Create post button in app bar.
- `app_bar_profile_drawer` — Profile/drawer button in app bar.
- `comment_submit` — Send comment button.
- `login_sign_in_button` — Sign-in button on login screen (Continue with Google / Apple).

Flows also use visible text (e.g. "Feed", "Post", "What's on your mind?", "Write a comment...") for stability across i18n when IDs are not required.

## Troubleshooting

- **Maestro can't find element**: Ensure the app is built and launched (e.g. via crux). Use `maestro studio` to inspect the running app and adjust selectors.
- **Two devices**: Run crux so both iOS and Android apps are running. To run Maestro on a specific device, set `MAESTRO_DEVICE_ID_IOS` or `MAESTRO_DEVICE_ID_ANDROID` (e.g. from `flutter devices` or `xcrun simctl list`).
- **Reset script fails**: Ensure Postgres is running and `DATABASE_URL` (or `PGHOST`, `PGPORT`, etc.) matches your backend. Run migrations first.
