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
