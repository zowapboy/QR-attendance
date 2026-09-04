# QR Attendance project workflow

## 1. Confirm prerequisites

Install Flutter (stable channel), Dart, Android Studio/SDK, and a Google account with access to Apps Script and Google Sheets. From `attendance_app`, run:

```bash
flutter doctor
flutter create .
flutter pub get
```

`flutter create .` fills the Android host files while preserving the existing `lib/` and `pubspec.yaml`; review its generated changes before committing.

## 2. Create the database

Create one Google Spreadsheet and add only `Members`, `Attendance`, and `Settings`. Use the schemas in `google_sheet/README.md`, add sample users/settings, and record the spreadsheet ID for Apps Script.

## 3. Build and deploy the backend

Create an Apps Script project, copy in the single `apps_script/Code.gs` file, configure the spreadsheet ID and constants, and implement the `health`, `login`, `getDashboard`, `submitAttendance`, and `logout` actions. Test login, first-device binding, wrong-device rejection, QR/BSSID checks, server-time rules, duplicate protection, dashboard analytics, and JSON error responses before connecting Flutter. Deploy as a web app over HTTPS and distribute its `/exec` URL to app users.

## 4. Build the Flutter client

Add the smallest required packages for HTTPS requests, secure local storage, QR scanning, and Wi-Fi BSSID access. On a fresh installation, request the Apps Script `/exec` URL before Login, validate it with `health`, and save it locally. Implement the API service, persistent device ID, login persistence, dashboard response models, and the two main screens. The dashboard must always render scanner visibility from `getDashboard`, not only from local time/state.

## 5. Integrate and verify

Enter the Apps Script `/exec` URL on a real Android device, then test the complete flow on each allowed network. Verify successful scans return `Recorded` and close the scanner; failures leave it available and show the required worker-facing message. Run the full test matrix in `AGENTS.md`, including app-link validation/persistence, 07:00 boundaries, 09:00 reporting boundaries, retries, app restart, month transitions, and network/backend errors.

## 6. Release checklist

Before release, verify HTTPS is used, the private spreadsheet's numeric PIN values are not shared publicly, sessions/device IDs are stored securely, only minimum Android permissions are requested, no debug errors are shown to workers, historical rows remain intact, and no non-goal features have been introduced.

## 7. Planned Public branch workflow

The working internal app remains on `main` with its fixed Apps Script endpoint. Create the `Public` branch from a verified `main` commit only when public distribution work begins. Do not merge its app-link onboarding flow back into the internal build without an explicit decision.

### Public app flow

```text
URL Setup -> Login -> Dashboard
```

1. On first launch, show a single URL Setup screen before Login.
2. Accept only HTTPS Apps Script production URLs ending in `/exec`.
3. Validate the endpoint with a non-mutating request, then save it in secure storage for future launches.
4. Once a URL is saved, bypass URL Setup and use the usual saved-session/Login flow.
5. The public URL is an endpoint address, not administrator access to the private spreadsheet.

### Sheet-managed holidays

Add a `Holidays` tab for one-off closures:

| date | holiday_name | active | created_at |
| --- | --- | --- | --- |
| 2026-10-02 | Gandhi Jayanti | TRUE | 2026-09-04 |

- The sheet owner enters and maintains holiday rows manually; employees cannot edit holidays in the app.
- Dates use `YYYY-MM-DD`; `active` accepts `TRUE`, `YES`, or `1`.
- Every Sunday is an automatic weekly holiday. It needs no `Holidays` row.
- A Sunday that also appears in `Holidays` still counts as one closed day.
- Apps Script is the authority: `getDashboard` returns the holiday state and `submitAttendance` rejects submissions on holidays.
- On a holiday, the Dashboard names the holiday and keeps the QR scanner closed. The next non-holiday day's scanner can open at 07:00 Asia/Kolkata.

### Attendance summary tabs

Apps Script will generate and refresh monthly member-performance summaries from `Members`, `Attendance`, and `Holidays`:

- `Summary - Current` shows the current calendar month.
- `Summary - YYYY-MM` tabs preserve historical monthly views, for example `Summary - 2026-09`.

Each summary row includes:

| month | username | work_days | holidays | present_days | absent_days | attendance_percent | early_days | early_minutes | on_time_days | late_days | late_minutes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

`work_days` is calendar days minus every Sunday and active assigned holidays. No additional Sunday or weekly rule is inferred.

### Public branch implementation order

1. Create `Public` from the approved `main` release.
2. Re-enable configurable app-link storage only in `Public` and add the URL Setup gate.
3. Add `Holidays` table access and server-side holiday checks.
4. Return holiday state from Dashboard and render the scanner-closed holiday state.
5. Add monthly-summary generation and refresh it after attendance writes.
6. Test fresh URL setup, stored URL reuse, Sunday closure, one-off holidays, the next eligible 07:00 opening, attendance rejection on closed days, and current/previous-month summaries.
